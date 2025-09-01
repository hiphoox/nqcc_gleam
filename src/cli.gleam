import argv
import gleam/io
import gleam/result
import glint
import settings

/// Configuration structure for compiler invocation
///
/// Compilation configuration design:
/// - Encapsulates all user-specified compilation options
/// - Separates CLI parsing from compilation logic
/// - Makes configuration explicit and testable
/// - Enables different CLI interfaces to produce same config
///
/// Field purposes:
/// - stage: Which compilation stage to stop at (lex/parse/codegen/assembly/executable)
/// - platform: Target platform for code generation (Linux/OSX calling conventions)
/// - object: Whether to stop at object file generation (.o files)
/// - src_file: Input source file path to compile
///
/// Why this design:
/// - Single source of truth for compilation parameters
/// - Decouples CLI argument parsing from compilation logic
/// - Enables easy testing with different configurations
/// - Makes configuration serializable and transferable
/// - Follows separation of concerns principle
pub type Config {
  Config(
    stage: settings.Stage,
    platform: settings.Platform,
    object: Bool,
    clean: Bool,
    src_file: String,
  )
}

/// Create the CLI application with proper command structure and help
///
/// Application setup strategy:
/// - Use glint library for professional CLI argument parsing
/// - Configure application name for help messages and error output
/// - Enable automatic help generation with formatting
/// - Register main command handler with dependency injection
///
/// Dependency injection approach:
/// - Accept command_handler function to decouple CLI from business logic
/// - Enables different handlers for testing vs production
/// - Makes the CLI framework reusable across different execution contexts
/// - Follows inversion of control principle
///
/// Why glint library:
/// - Professional CLI parsing with validation and help generation
/// - Handles edge cases in argument parsing automatically
/// - Provides consistent error messages and user experience
/// - Supports complex flag combinations and validation
/// - Standard library in Gleam ecosystem for CLI applications
pub fn create_app(command_handler: fn(Config) -> Nil) -> glint.Glint(Nil) {
  glint.new()
  |> glint.with_name("nqcc")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: nqcc_command(command_handler))
}

/// Execute the CLI application with command line arguments
///
/// Application execution strategy:
/// - Load arguments from the system's command line interface
/// - Pass arguments to glint for parsing and command dispatch
/// - Handle all argument parsing errors through glint's error system
/// - Provide clean separation between app creation and execution
///
/// Why separate from create_app:
/// - Enables testing with different argument sets
/// - Clean separation of app configuration vs execution
/// - Makes argument source explicit (system vs test data)
/// - Follows single responsibility principle
/// - Enables reuse of same app with different argument sources
pub fn run_app(app: glint.Glint(Nil)) -> Nil {
  glint.run(app, argv.load().arguments)
}

/// Define the main compiler command with all flags and argument parsing
///
/// Command definition strategy:
/// - Require at least one unnamed argument (the source file)
/// - Define all compilation control flags with defaults and help text
/// - Use glint's flag system for automatic validation and help generation
/// - Parse flags into structured configuration for business logic
///
/// Flag design rationale:
/// - Boolean flags for compilation stages (--lex, --parse, --codegen, -s, --object)
/// - Stage flags are mutually exclusive with priority order
/// - Object flag (--object) for separate compilation without linking
/// - Target platform flag for cross-compilation support
/// - Short names (-s) for commonly used flags
///
/// Why this flag structure:
/// - Matches standard compiler interfaces (gcc, clang)
/// - Progressive stages allow debugging compilation pipeline
/// - Platform targeting enables cross-compilation
/// - Object generation supports separate compilation workflow
/// - Follows Unix command line conventions
fn nqcc_command(command_handler: fn(Config) -> Nil) -> glint.Command(Nil) {
  use <- glint.command_help("A C compiler written in Gleam")
  use <- glint.unnamed_args(glint.MinArgs(1))

  use lex_flag <- glint.flag(
    glint.bool_flag("lex")
    |> glint.flag_default(False)
    |> glint.flag_help("Run the lexer only"),
  )

  use parse_flag <- glint.flag(
    glint.bool_flag("parse")
    |> glint.flag_default(False)
    |> glint.flag_help("Run the lexer and parser only"),
  )

  use codegen_flag <- glint.flag(
    glint.bool_flag("codegen")
    |> glint.flag_default(False)
    |> glint.flag_help(
      "Run through code generation but stop before emitting assembly",
    ),
  )

  use assembly_flag <- glint.flag(
    glint.bool_flag("s")
    |> glint.flag_default(False)
    |> glint.flag_help("Stop before assembling (keep .s file)"),
  )

  use object_flag <- glint.flag(
    glint.bool_flag("object")
    |> glint.flag_default(False)
    |> glint.flag_help("Generate object file (.o) without linking"),
  )

  use clean_flag <- glint.flag(
    glint.bool_flag("clean")
    |> glint.flag_default(False)
    |> glint.flag_help("Clean intermediate (.s, .o) and executable files"),
  )

  use target_opt <- glint.flag(
    glint.string_flag("target")
    |> glint.flag_default("osx")
    |> glint.flag_help("Choose target platform (linux, osx)"),
  )

  use _named_args, args, flags <- glint.command()

  let assert Ok(lex) = lex_flag(flags)
  let assert Ok(parse) = parse_flag(flags)
  let assert Ok(codegen) = codegen_flag(flags)
  let assert Ok(assembly) = assembly_flag(flags)
  let assert Ok(object) = object_flag(flags)
  let assert Ok(clean) = clean_flag(flags)
  let assert Ok(target_str) = target_opt(flags)

  case args {
    [] -> {
      // Defensive programming: MinArgs(1) should prevent this, but handle gracefully
      // Shows clear error message if validation fails
      io.println("Error: No source file provided")
    }
    [src_file, ..] -> {
      // Parse and validate all flags into structured configuration
      // Delegate to command_handler for actual compilation logic
      case
        parse_config(
          lex,
          parse,
          codegen,
          assembly,
          object,
          clean,
          target_str,
          src_file,
        )
      {
        Ok(config) -> command_handler(config)
        Error(e) -> io.println("Error: " <> e)
      }
    }
  }
}

/// Convert raw CLI flags into structured configuration with validation
///
/// Configuration parsing strategy:
/// - Resolve stage priority when multiple stage flags are provided
/// - Validate platform string against supported targets
/// - Preserve all other settings as-is (object, src_file)
/// - Return detailed error messages for invalid combinations
///
/// Stage resolution logic:
/// - Priority order: lex > parse > codegen > assembly > executable
/// - Earlier stages take precedence when multiple flags are specified
/// - Default to executable when no stage flags are provided
/// - Matches standard compiler behavior (early exit on first stage flag)
///
/// Why this priority system:
/// - Users expect --lex to override --parse (more specific wins)
/// - Allows users to add flags without changing behavior
/// - Provides predictable behavior regardless of flag order
/// - Follows principle of least surprise for command line tools
/// - Enables scripts to safely add compilation stage flags
///
/// Platform validation approach:
/// - Explicit whitelist of supported platforms
/// - Clear error messages for unsupported platforms
/// - Case-sensitive matching for consistency
/// - Room for future platform additions
pub fn parse_config(
  lex: Bool,
  parse: Bool,
  codegen: Bool,
  assembly: Bool,
  object: Bool,
  clean: Bool,
  target_str: String,
  src_file: String,
) -> Result(Config, String) {
  // Determine compilation stage with priority-based resolution
  // Earlier stages override later stages for predictable behavior
  let stage = case lex, parse, codegen, assembly, object {
    True, _, _, _, _ -> settings.Lex
    False, True, _, _, _ -> settings.Parse
    False, False, True, _, _ -> settings.Codegen
    False, False, False, True, _ -> settings.Assembly
    False, False, False, False, True -> settings.Object
    False, False, False, False, False -> settings.Executable
  }

  // Validate and parse target platform string
  // Explicit validation provides clear error messages
  use platform <- result.try(case target_str {
    "linux" -> Ok(settings.Linux)
    "osx" -> Ok(settings.OSX)
    _ -> Error("Invalid platform: " <> target_str <> ". Use 'linux' or 'osx'")
  })

  Ok(Config(
    stage: stage,
    platform: platform,
    object: object,
    clean: clean,
    src_file: src_file,
  ))
}
