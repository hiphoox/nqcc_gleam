import gleeunit

// Import all test modules
import codegen_test
import compiler_test
import emitter_test
import lexer_test
import parser_test

pub fn main() {
  gleeunit.main()
}

// Re-export all test functions to ensure they are discovered by the test runner

// Lexer tests
pub fn lex_empty_input_test() {
  lexer_test.lex_empty_input_test()
}

pub fn lex_simple_return_statement_test() {
  lexer_test.lex_simple_return_statement_test()
}

pub fn lex_function_definition_test() {
  lexer_test.lex_function_definition_test()
}

pub fn lex_with_whitespace_test() {
  lexer_test.lex_with_whitespace_test()
}

pub fn lex_identifiers_test() {
  lexer_test.lex_identifiers_test()
}

pub fn lex_integer_literals_test() {
  lexer_test.lex_integer_literals_test()
}

pub fn lex_keywords_test() {
  lexer_test.lex_keywords_test()
}

pub fn lex_punctuation_test() {
  lexer_test.lex_punctuation_test()
}

pub fn lex_mixed_tokens_test() {
  lexer_test.lex_mixed_tokens_test()
}

pub fn lex_newlines_and_tabs_test() {
  lexer_test.lex_newlines_and_tabs_test()
}

pub fn lex_arithmetic_expressions_test() {
  lexer_test.lex_arithmetic_expressions_test()
}

pub fn lex_void_function_test() {
  lexer_test.lex_void_function_test()
}

pub fn lex_large_numbers_test() {
  lexer_test.lex_large_numbers_test()
}

pub fn lex_error_invalid_character_test() {
  lexer_test.lex_error_invalid_character_test()
}

pub fn lex_error_invalid_token_test() {
  lexer_test.lex_error_invalid_token_test()
}

// Parser tests
pub fn parse_empty_token_list_test() {
  parser_test.parse_empty_token_list_test()
}

pub fn parse_simple_function_test() {
  parser_test.parse_simple_function_test()
}

pub fn parse_function_with_zero_return_test() {
  parser_test.parse_function_with_zero_return_test()
}

pub fn parse_function_with_large_number_test() {
  parser_test.parse_function_with_large_number_test()
}

pub fn parse_function_with_different_name_test() {
  parser_test.parse_function_with_different_name_test()
}

pub fn parse_error_missing_return_type_test() {
  parser_test.parse_error_missing_return_type_test()
}

pub fn parse_error_missing_function_name_test() {
  parser_test.parse_error_missing_function_name_test()
}

pub fn parse_error_missing_open_paren_test() {
  parser_test.parse_error_missing_open_paren_test()
}

pub fn parse_error_missing_close_paren_test() {
  parser_test.parse_error_missing_close_paren_test()
}

pub fn parse_error_missing_open_brace_test() {
  parser_test.parse_error_missing_open_brace_test()
}

pub fn parse_error_missing_close_brace_test() {
  parser_test.parse_error_missing_close_brace_test()
}

pub fn parse_error_missing_return_keyword_test() {
  parser_test.parse_error_missing_return_keyword_test()
}

pub fn parse_error_missing_semicolon_test() {
  parser_test.parse_error_missing_semicolon_test()
}

pub fn parse_error_unexpected_token_test() {
  parser_test.parse_error_unexpected_token_test()
}

pub fn parse_error_premature_end_test() {
  parser_test.parse_error_premature_end_test()
}

pub fn parse_error_extra_tokens_test() {
  parser_test.parse_error_extra_tokens_test()
}

// Codegen tests
pub fn generate_simple_function_test() {
  codegen_test.generate_simple_function_test()
}

pub fn generate_function_with_zero_return_test() {
  codegen_test.generate_function_with_zero_return_test()
}

pub fn generate_function_with_different_name_test() {
  codegen_test.generate_function_with_different_name_test()
}

pub fn generate_function_with_large_number_test() {
  codegen_test.generate_function_with_large_number_test()
}

pub fn generate_function_with_negative_number_test() {
  codegen_test.generate_function_with_negative_number_test()
}

pub fn generate_preserves_function_name_test() {
  codegen_test.generate_preserves_function_name_test()
}

pub fn generate_creates_correct_instruction_count_test() {
  codegen_test.generate_creates_correct_instruction_count_test()
}

pub fn generate_first_instruction_is_mov_test() {
  codegen_test.generate_first_instruction_is_mov_test()
}

pub fn generate_second_instruction_is_ret_test() {
  codegen_test.generate_second_instruction_is_ret_test()
}

pub fn generate_mov_uses_immediate_operand_test() {
  codegen_test.generate_mov_uses_immediate_operand_test()
}

pub fn generate_mov_targets_register_test() {
  codegen_test.generate_mov_targets_register_test()
}

// Emitter tests
pub fn emit_simple_assembly_test() {
  emitter_test.emit_simple_assembly_test()
}

pub fn emit_creates_file_with_content_test() {
  emitter_test.emit_creates_file_with_content_test()
}

pub fn emit_different_function_names_test() {
  emitter_test.emit_different_function_names_test()
}

pub fn emit_different_immediate_values_test() {
  emitter_test.emit_different_immediate_values_test()
}

pub fn emit_negative_immediate_values_test() {
  emitter_test.emit_negative_immediate_values_test()
}

pub fn emit_macos_platform_test() {
  emitter_test.emit_macos_platform_test()
}

pub fn emit_creates_proper_s_extension_test() {
  emitter_test.emit_creates_proper_s_extension_test()
}

pub fn emit_overwrites_existing_file_test() {
  emitter_test.emit_overwrites_existing_file_test()
}

// Compiler tests
pub fn compile_lex_stage_valid_source_test() {
  compiler_test.compile_lex_stage_valid_source_test()
}

pub fn compile_parse_stage_valid_source_test() {
  compiler_test.compile_parse_stage_valid_source_test()
}

pub fn compile_codegen_stage_valid_source_test() {
  compiler_test.compile_codegen_stage_valid_source_test()
}

pub fn compile_assembly_stage_valid_source_test() {
  compiler_test.compile_assembly_stage_valid_source_test()
}

pub fn compile_executable_stage_valid_source_test() {
  compiler_test.compile_executable_stage_valid_source_test()
}

pub fn compile_macos_platform_test() {
  compiler_test.compile_macos_platform_test()
}

pub fn compile_file_not_found_error_test() {
  compiler_test.compile_file_not_found_error_test()
}

pub fn compile_lex_error_invalid_character_test() {
  compiler_test.compile_lex_error_invalid_character_test()
}

pub fn compile_parse_error_invalid_syntax_test() {
  compiler_test.compile_parse_error_invalid_syntax_test()
}

pub fn compile_parse_error_missing_semicolon_test() {
  compiler_test.compile_parse_error_missing_semicolon_test()
}

pub fn compile_empty_file_test() {
  compiler_test.compile_empty_file_test()
}

pub fn compile_whitespace_only_test() {
  compiler_test.compile_whitespace_only_test()
}

pub fn compile_different_function_names_test() {
  compiler_test.compile_different_function_names_test()
}

pub fn compile_multiple_stages_same_file_test() {
  compiler_test.compile_multiple_stages_same_file_test()
}
