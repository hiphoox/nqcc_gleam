import compiler
import gleam/string
import gleeunit/should
import settings
import simplifile

pub fn compile_lex_stage_valid_source_test() {
  let test_file = "test_lex.c"
  let source = "int main(void) { return 42; }"

  // Create test file
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Lex, test_file, settings.Linux)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn compile_parse_stage_valid_source_test() {
  let test_file = "test_parse.c"
  let source = "int main(void) { return 0; }"

  // Create test file
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Parse, test_file, settings.Linux)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn compile_codegen_stage_valid_source_test() {
  let test_file = "test_codegen.c"
  let source = "int foo(void) { return 123; }"

  // Create test file
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Codegen, test_file, settings.Linux)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn compile_assembly_stage_valid_source_test() {
  let test_file = "test_assembly.c"
  let source = "int main(void) { return 42; }"

  // Create test file
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Assembly, test_file, settings.Linux)
  |> should.be_ok()

  // Verify assembly file was created
  let asm_file = "test_assembly.s"
  simplifile.read(asm_file)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
  let _ = simplifile.delete(asm_file)
}

pub fn compile_executable_stage_valid_source_test() {
  let test_file = "test_executable.c"
  let source = "int main(void) { return 0; }"

  // Create test file
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Executable, test_file, settings.Linux)
  |> should.be_ok()

  // Verify assembly file was created
  let asm_file = "test_executable.s"
  simplifile.read(asm_file)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
  let _ = simplifile.delete(asm_file)
}

pub fn compile_macos_platform_test() {
  let test_file = "test_macos.c"
  let source = "int main(void) { return 1; }"

  // Create test file
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Assembly, test_file, settings.OSX)
  |> should.be_ok()

  // Verify assembly file was created
  let asm_file = "test_macos.s"
  simplifile.read(asm_file)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
  let _ = simplifile.delete(asm_file)
}

pub fn compile_file_not_found_error_test() {
  let nonexistent_file = "does_not_exist.c"

  compiler.compile(settings.Lex, nonexistent_file, settings.Linux)
  |> should.be_error()
}

pub fn compile_lex_error_invalid_character_test() {
  let test_file = "test_lex_error.c"
  let source = "int main(void) { return @; }"

  // Create test file with invalid character
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Lex, test_file, settings.Linux)
  |> should.be_error()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn compile_parse_error_invalid_syntax_test() {
  let test_file = "test_parse_error.c"
  let source = "int main(void { return 42; }"

  // Create test file with syntax error (missing closing paren)
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Parse, test_file, settings.Linux)
  |> should.be_error()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn compile_parse_error_missing_semicolon_test() {
  let test_file = "test_parse_error2.c"
  let source = "int main(void) { return 42 }"

  // Create test file with syntax error (missing semicolon)
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Parse, test_file, settings.Linux)
  |> should.be_error()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn compile_empty_file_test() {
  let test_file = "test_empty.c"
  let source = ""

  // Create empty test file
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Lex, test_file, settings.Linux)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn compile_whitespace_only_test() {
  let test_file = "test_whitespace.c"
  let source = "   \n\t   \n  "

  // Create test file with only whitespace
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Lex, test_file, settings.Linux)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn compile_different_function_names_test() {
  let test_file = "test_different_names.c"
  let source = "int my_custom_function(void) { return 999; }"

  // Create test file
  let _ = simplifile.write(test_file, source)

  compiler.compile(settings.Assembly, test_file, settings.Linux)
  |> should.be_ok()

  // Verify assembly file contains function name
  let asm_file = "test_different_names.s"
  case simplifile.read(asm_file) {
    Ok(content) -> {
      string.contains(content, "my_custom_function")
      |> should.be_true()
    }
    Error(_) -> should.be_true(False)
  }

  // Clean up
  let _ = simplifile.delete(test_file)
  let _ = simplifile.delete(asm_file)
}

pub fn compile_multiple_stages_same_file_test() {
  let test_file = "test_multiple.c"
  let source = "int test(void) { return 5; }"

  // Create test file
  let _ = simplifile.write(test_file, source)

  // Test multiple stages work with same file
  compiler.compile(settings.Lex, test_file, settings.Linux)
  |> should.be_ok()

  compiler.compile(settings.Parse, test_file, settings.Linux)
  |> should.be_ok()

  compiler.compile(settings.Codegen, test_file, settings.Linux)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}
