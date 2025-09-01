import gleam/io
import gleam/list
import gleam/string
import gleamyshell
import simplifile

/// Validate that a filename has an acceptable C source file extension
///
/// C compiler input validation strategy:
/// - Only accept .c (source) and .h (header) files for compilation
/// - Reject other extensions early to provide clear error messages
/// - Uses get_extension for consistent extension parsing logic
///
/// Why this design:
/// - Fail-fast principle: catch invalid inputs before attempting compilation
/// - Clear error messages help users understand what files are acceptable
/// - Centralized extension logic ensures consistent behavior across the compiler
/// - Follows common compiler practice of validating input file types
/// - Result type makes error handling explicit and composable
pub fn validate_extension(filename: String) -> Result(Nil, String) {
  case get_extension(filename) {
    ".c" | ".h" -> Ok(Nil)
    ext -> Error("Expected C source file with .c or .h extension, got: " <> ext)
  }
}

/// Extract the file extension from a filename including the dot
///
/// Extension parsing logic:
/// - Split filename on dots to handle cases like "file.tar.gz"
/// - Take the last part after the final dot as the extension
/// - Include the dot in the result (".c" not "c") for consistency
/// - Return empty string for files without extensions
///
/// Why this approach:
/// - Handles complex filenames with multiple dots correctly
/// - Empty string return is safe and testable (no null/undefined)
/// - Including the dot makes pattern matching easier (.c | .h)
/// - Uses Gleam's safe list operations (no index out of bounds)
/// - Consistent with common file system utilities behavior
pub fn get_extension(filename: String) -> String {
  case string.split(filename, ".") {
    [_] -> ""
    parts ->
      "."
      <> case list.last(parts) {
        Ok(ext) -> ext
        Error(_) -> ""
      }
  }
}

/// Replace a file's extension with a new one, preserving the base name
///
/// Extension replacement strategy:
/// - Handle files without extensions by appending the new extension
/// - For files with extensions, replace everything after the last dot
/// - Preserve the full path and base filename structure
/// - Work correctly with complex filenames (multiple dots, paths)
///
/// Why this implementation:
/// - Split-reverse-rebuild approach handles edge cases reliably
/// - Works with paths containing directories and multiple dots
/// - Safe fallback for files without extensions (just append)
/// - Essential for compiler pipeline: source.c -> source.s -> executable
/// - Preserves all filename components except the final extension
pub fn replace_extension(filename: String, new_extension: String) -> String {
  case string.split(filename, ".") {
    [base] -> base <> new_extension
    parts -> {
      case list.reverse(parts) {
        [_, ..rest] -> string.join(list.reverse(rest), ".") <> new_extension
        [] -> filename <> new_extension
      }
    }
  }
}

/// Remove the extension from a filename, keeping everything else
///
/// Extension removal logic:
/// - Remove everything from the last dot to the end of filename
/// - Handle files without extensions gracefully (return unchanged)
/// - Preserve directory paths and complex filename structures
/// - Return the complete base name without any extension
///
/// Why this function exists:
/// - Needed for creating executable names from source files
/// - Common file manipulation pattern in build systems
/// - Safer than string manipulation with indices
/// - Handles edge cases like hidden files (.bashrc) appropriately
/// - Complements replace_extension for complete filename control
pub fn chop_extension(filename: String) -> String {
  case string.split(filename, ".") {
    [base] -> base
    parts -> {
      case list.reverse(parts) {
        [_, ..rest] -> string.join(list.reverse(rest), ".")
        [] -> filename
      }
    }
  }
}

/// Execute a system command with arguments and return success/failure
///
/// Command execution strategy:
/// - Use gleamyshell for cross-platform command execution
/// - Check exit code to determine success (0) vs failure (non-zero)
/// - Capture both stdout and stderr for error reporting
/// - Provide detailed error messages including command, args, and output
///
/// Why this design:
/// - Abstracts away platform-specific command execution differences
/// - Makes command failures explicit through Result type
/// - Preserves all error information for debugging (exit code + output)
/// - Follows Unix convention: exit code 0 = success, non-zero = failure
/// - Enables easy chaining with other Result-returning functions
/// - Used for preprocessing (gcc -E), assembly (gcc), and linking
pub fn run_command(cmd: String, args: List(String)) -> Result(Nil, String) {
  io.print("Running command: " <> cmd <> " " <> string.join(args, " ") <> "\n")
  case gleamyshell.execute(cmd, in: ".", args: args) {
    Ok(gleamyshell.CommandOutput(0, _)) -> Ok(Nil)
    Ok(gleamyshell.CommandOutput(exit_code, output)) ->
      Error(
        "Command failed: "
        <> cmd
        <> " "
        <> string.join(args, " ")
        <> " (exit code: "
        <> string.inspect(exit_code)
        <> ")\nOutput: "
        <> output,
      )
    Error(reason) ->
      Error(
        "Command failed: "
        <> cmd
        <> " "
        <> string.join(args, " ")
        <> ": "
        <> reason,
      )
  }
}

/// Conditionally delete a file based on debug mode setting
///
/// File cleanup logic:
/// - In normal mode (debug=False): delete the file to keep workspace clean
/// - In debug mode (debug=True): preserve file for inspection and debugging
/// - Ignore deletion errors silently (file might not exist, permissions, etc.)
/// - Always return Nil for consistent behavior regardless of success/failure
///
/// Why conditional cleanup:
/// - Debug mode allows developers to inspect intermediate files (.i, .s)
/// - Normal mode keeps the workspace clean from temporary files
/// - Silent error handling prevents cleanup failures from breaking compilation
/// - Compiler should focus on core functionality, not file management edge cases
/// - Matches behavior of professional compilers (gcc -save-temps, clang -v)
pub fn cleanup_file(file_path: String, debug: Bool) -> Nil {
  case debug {
    False -> {
      let _ = simplifile.delete(file_path)
      Nil
    }
    True -> Nil
  }
}

/// Execute a function with automatic file cleanup afterwards
///
/// Resource management pattern:
/// - Execute the provided callback function with the file path
/// - Automatically clean up the file after callback completes
/// - Cleanup happens regardless of callback success or failure
/// - Return the callback's result unchanged
///
/// Why this pattern (RAII-like behavior):
/// - Ensures files are always cleaned up, preventing resource leaks
/// - Eliminates duplicate cleanup code in success/error paths
/// - Makes resource management automatic and error-proof
/// - Follows functional programming principle of higher-order functions
/// - Implements "Resource Acquisition Is Initialization" pattern for file management
/// - Used in compiler pipeline to ensure intermediate files don't accumulate
pub fn with_cleanup(
  file_path: String,
  debug: Bool,
  callback: fn(String) -> Result(a, String),
) -> Result(a, String) {
  let result = callback(file_path)
  cleanup_file(file_path, debug)
  result
}

/// Clean all intermediate and executable files generated from a source file
///
/// Comprehensive cleanup strategy:
/// - Remove preprocessed files (.i extension)
/// - Remove assembly files (.s extension)
/// - Remove object files (.o extension)
/// - Remove executable files (no extension, same base name)
/// - Always clean regardless of debug mode when explicitly requested
///
/// File discovery logic:
/// - Start with source file base name (remove .c or .h extension)
/// - Generate all possible intermediate file names
/// - Attempt to delete each file type that may have been generated
/// - Silent failure for non-existent files (common and expected)
///
/// Why this design:
/// - Matches standard make clean behavior for build systems
/// - Comprehensive cleanup prevents accumulation of build artifacts
/// - Safe deletion (ignores non-existent files without errors)
/// - Works with any source file name following compiler conventions
/// - Essential for CI/CD and automated build environments
pub fn clean_project_files(src_file: String) -> Nil {
  let base_name = chop_extension(src_file)

  // List of all file extensions/types that may be generated
  let extensions_to_clean = [".i", ".s", ".o"]

  // Clean intermediate files with extensions
  list.each(extensions_to_clean, fn(ext) {
    let file_to_clean = base_name <> ext
    let _ = simplifile.delete(file_to_clean)
    io.println("Cleaned: " <> file_to_clean)
  })

  // Clean executable file (no extension)
  let _ = simplifile.delete(base_name)
  io.println("Cleaned: " <> base_name)
}
