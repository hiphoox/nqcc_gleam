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
/// - Execute core compilation stages directly on source (lex/parse/codegen/emit)
/// - Handle assembly and linking for executable generation
/// - Automatic cleanup of intermediate files after compilation
///
/// Resource management strategy:
/// - Use with_cleanup for automatic file cleanup (RAII pattern)
/// - Assembly files are cleaned up after linking for executable stage
/// - Object files are preserved for separate compilation workflow
///
/// Error handling approach:
/// - Fail fast on invalid file extensions
/// - Propagate detailed errors from each compilation stage
/// - Clean up resources even when errors occur
/// - Provide context-specific error messages for debugging
///
/// Why this pipeline design:
/// - Works directly with C source code without external preprocessing
/// - Separates concerns: compilation vs linking
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
      // Compile directly with source file
      case compiler.compile(config.stage, config.src_file, config.platform) {
        Ok(_) -> {
          // Handle post-compilation steps based on stage
          case config.stage {
            settings.Object -> {
              let assembly_file = utils.replace_extension(config.src_file, ".s")
              assemble_to_object(assembly_file)
            }
            settings.Executable -> {
              let assembly_file = utils.replace_extension(config.src_file, ".s")
              assemble_and_link(assembly_file)
            }
            _ -> Ok(Nil)
          }
        }
        Error(e) -> Error("Compilation failed: " <> string.inspect(e))
      }
    }
  }
}

/// Convert assembly code to object file (.o) without linking
///
/// Object file generation strategy:
/// - Use GCC to assemble .s file into .o object file
/// - Stop before linking step to produce relocatable object file
/// - Preserve assembly file after object generation
/// - Generate .o file with same base name as assembly file
///
/// Why generate object files:
/// - Enables separate compilation and later linking
/// - Standard practice in multi-file C projects
/// - Allows inspection of object code and symbols
/// - Matches gcc -c flag behavior
fn assemble_to_object(assembly_file: String) -> Result(Nil, String) {
  let object_file = utils.replace_extension(assembly_file, ".o")
  case utils.run_command("gcc", ["-c", assembly_file, "-o", object_file]) {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error("Object file generation failed")
  }
}

/// Convert assembly code to executable binary through assembling and linking
///
/// Assembly and linking strategy:
/// - Use GCC as assembler and linker for platform compatibility
/// - Generate executable with same base name as assembly file
/// - Handle platform-specific object file formats and linking
/// - Clean up intermediate assembly files after linking
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
fn assemble_and_link(assembly_file: String) -> Result(Nil, String) {
  utils.with_cleanup(assembly_file, False, fn(assembly_file) {
    let output_file = utils.chop_extension(assembly_file)
    case utils.run_command("gcc", [assembly_file, "-o", output_file]) {
      Ok(_) -> Ok(Nil)
      Error(_) -> Error("Assembly and linking failed")
    }
  })
}
