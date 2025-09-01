import cli
import compiler
import gleam/io
import gleam/result
import gleam/string
import settings

import utils

/// Main entry point for the nqcc C compiler
///
/// Application bootstrap strategy:
/// - Create CLI application with command configuration
/// - Delegate command handling to separate function for testability
/// - Use dependency injection pattern for clean separation of concerns
/// - Keep main function minimal and focused on application setup
///
/// Why this design:
/// - Separates CLI setup from business logic (single responsibility)
/// - Makes the application testable by injecting different handlers
/// - Follows standard pattern for CLI applications in functional languages
/// - Enables different execution contexts (testing, production, etc.)
/// - Clean separation allows easy modification of CLI behavior
pub fn main() -> Nil {
  let app = cli.create_app(handle_command)
  cli.run_app(app)
}

/// Handle parsed command configuration and execute compilation
///
/// Command handling strategy:
/// - Receive validated configuration from CLI parsing
/// - Execute compilation pipeline with error handling
/// - Provide user-friendly success/error messages
/// - Convert Result types to appropriate exit behavior
///
/// Why separate from main:
/// - Enables testing with different configurations
/// - Isolates CLI parsing from compilation logic
/// - Makes error handling explicit and consistent
/// - Follows command pattern for user actions
/// - Simplifies main function to pure application setup
fn handle_command(config: cli.Config) -> Nil {
  case run_driver(config) {
    Ok(_) -> io.println("Compilation successful")
    Error(e) -> io.println("Error: " <> e)
  }
}

/// Main compilation driver that orchestrates the entire compilation pipeline
///
/// Compilation pipeline architecture:
/// - Validate input file extension for early error detection
/// - Preprocess source to handle #include and macros
/// - Execute core compilation stages (lex/parse/codegen/emit)
/// - Handle assembly and linking for executable generation
/// - Automatic cleanup of intermediate files with debug mode support
///
/// Resource management strategy:
/// - Use with_cleanup for automatic file cleanup (RAII pattern)
/// - Preprocessed files are always cleaned up after compilation
/// - Assembly files are cleaned up only for executable stage
/// - Debug mode preserves all intermediate files for inspection
///
/// Error handling approach:
/// - Fail fast on invalid file extensions
/// - Propagate detailed errors from each compilation stage
/// - Clean up resources even when errors occur
/// - Provide context-specific error messages for debugging
///
/// Why this pipeline design:
/// - Matches standard C compilation workflow (cpp -> cc1 -> as -> ld)
/// - Separates concerns: preprocessing vs compilation vs linking
/// - Enables partial compilation for debugging and development
/// - Automatic resource management prevents file system pollution
/// - Clear error propagation makes debugging compilation issues easier
fn run_driver(config: cli.Config) -> Result(Nil, String) {
  use _ <- result.try(utils.validate_extension(config.src_file))

  // Handle clean flag - remove intermediate and executable files
  case config.clean {
    True -> {
      utils.clean_project_files(config.src_file)
      Ok(Nil)
    }
    False -> {
      // Always preprocess first for all stages
      use preprocessed_file <- result.try(preprocess(config.src_file))

      // Use with_cleanup to automatically handle cleanup
      utils.with_cleanup(preprocessed_file, config.debug, fn(preprocessed_file) {
        // Compile to the specified stage
        case
          compiler.compile(config.stage, preprocessed_file, config.platform)
        {
          Ok(_) -> {
            // For executable stage, continue with assembly and linking
            case config.stage {
              settings.Executable -> {
                let assembly_file =
                  utils.replace_extension(preprocessed_file, ".s")
                assemble_and_link(assembly_file, config.debug)
              }
              _ -> Ok(Nil)
            }
          }
          Error(e) -> Error("Compilation failed: " <> string.inspect(e))
        }
      })
    }
  }
}

/// Run C preprocessor to handle #include directives and macro expansion
///
/// Preprocessing strategy:
/// - Use GCC preprocessor for standard C preprocessing behavior
/// - Generate .i file (preprocessed source) as intermediate representation
/// - Use -E flag to stop after preprocessing
/// - Use -P flag to omit line number information (cleaner output)
/// - Handle external dependencies (headers, macros) before our compiler stages
///
/// Why preprocessing is essential:
/// - Real C code uses #include for headers and standard library
/// - Macro expansion must happen before lexical analysis
/// - Preprocessor handles file inclusion, conditional compilation
/// - Our compiler can focus on core language features, not preprocessor complexity
/// - Matches standard C compilation pipeline (cpp -> cc1 -> as -> ld)
///
/// File naming convention:
/// - .i extension follows GCC convention for preprocessed C files
/// - Enables easy identification of compilation stage artifacts
/// - Consistent with other compilers and build systems
fn preprocess(src_file: String) -> Result(String, String) {
  let output_file = utils.replace_extension(src_file, ".i")
  case utils.run_command("gcc", ["-E", "-P", src_file, "-o", output_file]) {
    Ok(_) -> Ok(output_file)
    Error(_) -> Error("Preprocessing failed")
  }
}

/// Convert assembly code to executable binary through assembling and linking
///
/// Assembly and linking strategy:
/// - Use GCC as assembler and linker for platform compatibility
/// - Generate executable with same base name as assembly file
/// - Handle platform-specific object file formats and linking
/// - Automatic cleanup of assembly files unless in debug mode
///
/// Why use GCC for assembly/linking:
/// - Handles platform-specific assembler syntax and object formats
/// - Manages system libraries and runtime linkage automatically
/// - Provides consistent behavior across different operating systems
/// - Eliminates need to implement assembler and linker ourselves
/// - Matches standard compilation toolchain behavior
///
/// Executable naming logic:
/// - Remove .s extension to create executable name
/// - Follows Unix convention (source.c -> source executable)
/// - Enables easy execution of compiled programs
/// - Consistent with other compilers (gcc, clang)
///
/// Resource management:
/// - Automatic cleanup prevents accumulation of .s files
/// - Debug mode preserves assembly for inspection and debugging
/// - with_cleanup ensures consistent behavior on success/failure
fn assemble_and_link(assembly_file: String, debug: Bool) -> Result(Nil, String) {
  utils.with_cleanup(assembly_file, debug, fn(assembly_file) {
    let output_file = utils.chop_extension(assembly_file)
    case utils.run_command("gcc", [assembly_file, "-o", output_file]) {
      Ok(_) -> Ok(Nil)
      Error(_) -> Error("Assembly and linking failed")
    }
  })
}
