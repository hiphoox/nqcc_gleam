import assembly
import ast
import codegen
import emitter

import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import lexer
import parser
import settings
import simplifile
import tokens

/// Compilation error types representing all possible failure modes
///
/// Error hierarchy design:
/// - Each compilation stage can fail in specific ways
/// - Errors preserve original error information from each stage
/// - String-based errors for stages that don't have custom error types
/// - Enables precise error reporting and debugging
///
/// Why this approach:
/// - Explicit error types make all failure modes visible
/// - Error wrapping preserves context from each compilation stage
/// - Result type forces proper error handling at each level
/// - Easier to add new error types as compiler grows
/// - Follows functional programming principle of making errors explicit
pub type CompileError {
  LexError(lexer.LexError)
  ParseError(parser.ParseError)
  EmitError(String)
  IOError(String)
}

/// Main compilation entry point with stage-based compilation control
///
/// Compilation pipeline strategy:
/// - Each stage builds upon the previous stages' output
/// - Early exit when reaching the requested compilation stage
/// - Pipeline functions eliminate code duplication across stages
/// - File reading happens once, then data flows through stages
///
/// Stage progression logic:
/// - Lex: source → tokens (stop)
/// - Parse: source → tokens → AST (stop)
/// - Codegen: source → tokens → AST → assembly (stop)
/// - Assembly: source → tokens → AST → assembly → .s file (stop)
/// - Object: source → tokens → AST → assembly → .s file → .o file (stop)
/// - Executable: source → tokens → AST → assembly → .s file → executable
///
/// Why this design:
/// - Matches standard compiler architecture (gcc -E, -S, -c, -o flags)
/// - Each stage can be tested and debugged independently
/// - Pipeline pattern eliminates duplicate computation
/// - Clear separation of concerns between compilation stages
/// - Easy to add new intermediate representations or stages
/// - Follows functional programming composition principles
pub fn compile(
  stage: settings.Stage,
  src_file: String,
  platform: settings.Platform,
) -> Result(Nil, CompileError) {
  use source <- result.try(read_file(src_file))

  case stage {
    settings.Lex -> {
      use tokens <- result.try(compile_to_tokens(source))
      io.println("Tokens:")
      list.index_map(tokens, fn(token, index) {
        io.println(
          string.pad_start(int.to_string(index + 1), 3, " ")
          <> ": "
          <> format_token(token),
        )
      })
      |> list.each(fn(_) { Nil })
      Ok(Nil)
    }
    settings.Parse -> {
      use _ast <- result.try(compile_to_ast(source))
      Ok(Nil)
    }
    settings.Codegen -> {
      use _asm <- result.try(compile_to_asm(source))
      Ok(Nil)
    }
    settings.Assembly | settings.Object | settings.Executable -> {
      use asm <- result.try(compile_to_asm(source))
      let asm_filename = string.drop_end(src_file, 2) <> ".s"
      result.map_error(emitter.emit(asm_filename, asm, platform), EmitError)
    }
  }
}

/// Convert source code to token list (lexical analysis stage)
///
/// Lexical analysis purpose:
/// - Transform raw source text into structured token sequence
/// - Handle whitespace, comments, and lexical rules
/// - Detect invalid characters and lexical errors early
/// - Prepare structured input for syntax analysis
///
/// Why separate function:
/// - Reusable across multiple compilation stages
/// - Clear single responsibility (source → tokens)
/// - Enables isolated testing of lexical analysis
/// - Error mapping converts lexer errors to compiler errors
/// - Part of compilation pipeline pattern
fn compile_to_tokens(source: String) -> Result(List(tokens.Token), CompileError) {
  result.map_error(lexer.lex(source), LexError)
}

/// Convert source code to Abstract Syntax Tree (syntax analysis stage)
///
/// Syntax analysis pipeline:
/// - First perform lexical analysis to get tokens
/// - Then perform syntax analysis to build AST structure
/// - Check for syntax errors and malformed constructs
/// - Produce structured representation of program semantics
///
/// Why this approach:
/// - Builds on lexical analysis (don't repeat tokenization)
/// - Two-stage parsing follows standard compiler design
/// - AST representation enables semantic analysis and optimization
/// - Error handling preserves context from both lex and parse stages
/// - Pipeline composition makes data flow explicit
fn compile_to_ast(source: String) -> Result(ast.Program, CompileError) {
  use tokens <- result.try(compile_to_tokens(source))
  result.map_error(parser.parse(tokens), ParseError)
}

/// Convert source code to assembly representation (code generation stage)
///
/// Code generation pipeline:
/// - Perform lexical and syntax analysis to get AST
/// - Transform AST into target assembly instructions
/// - Handle platform-independent code generation
/// - Produce assembly that can be emitted to files
///
/// Why codegen doesn't return Result:
/// - Code generation from valid AST should always succeed
/// - AST structure guarantees we have valid program semantics
/// - No external dependencies or I/O in pure code generation
/// - Simplifies error handling - parser catches semantic errors
/// - If codegen fails, it indicates a compiler bug, not user error
fn compile_to_asm(source: String) -> Result(assembly.Assembly, CompileError) {
  use ast <- result.try(compile_to_ast(source))
  Ok(codegen.generate(ast))
}

/// Format a token for user-friendly display
///
/// Token formatting strategy:
/// - Show token type clearly with descriptive names
/// - Include associated data for tokens that carry information
/// - Use consistent formatting for readability
/// - Make output suitable for debugging and educational purposes
fn format_token(token: tokens.Token) -> String {
  case token {
    tokens.Identifier(name) -> "IDENTIFIER(\"" <> name <> "\")"
    tokens.Constant(value) -> "CONSTANT(" <> int.to_string(value) <> ")"
    tokens.KWInt -> "KEYWORD_INT"
    tokens.KWReturn -> "KEYWORD_RETURN"
    tokens.KWVoid -> "KEYWORD_VOID"
    tokens.OpenParen -> "OPEN_PAREN"
    tokens.CloseParen -> "CLOSE_PAREN"
    tokens.OpenBrace -> "OPEN_BRACE"
    tokens.CloseBrace -> "CLOSE_BRACE"
    tokens.Semicolon -> "SEMICOLON"
  }
}

/// Read source file content with proper error handling
///
/// File reading strategy:
/// - Use simplifile for cross-platform file operations
/// - Convert file system errors to compilation errors
/// - Return file content as string for lexical analysis
/// - Provide descriptive error messages with filename context
///
/// Why separate function:
/// - Centralizes file I/O error handling logic
/// - Converts external library errors to our error types
/// - Makes file reading explicit in compilation pipeline
/// - Enables easy testing with mock file systems
/// - Follows single responsibility principle
/// - Used once at start of compilation, before pure transformations
fn read_file(filename: String) -> Result(String, CompileError) {
  case simplifile.read(filename) {
    Ok(content) -> Ok(content)
    Error(_) -> Error(IOError("Could not read file: " <> filename))
  }
}
