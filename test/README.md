# NQCC Gleam Test Suite Documentation

This document provides comprehensive documentation for the unit test suite of the NQCC (Not Quite C Compiler) implementation in Gleam.

## Overview

The test suite provides comprehensive coverage of all major compiler stages, testing the main function of each stage independently while also verifying end-to-end integration. The tests are designed to ensure correctness, robustness, and maintainability of the compiler implementation.

## Test Structure

```
nqcc_gleam/test/
├── lexer_test.gleam      # Tests for lexer.lex()
├── parser_test.gleam     # Tests for parser.parse()
├── codegen_test.gleam    # Tests for codegen.generate()
├── emitter_test.gleam    # Tests for emitter.emit()
├── compiler_test.gleam   # Tests for compiler.compile()
├── nqcc_test.gleam      # Main test runner
└── README.md            # This documentation
```

## Test Coverage by Compiler Stage

### 1. Lexer Tests (`lexer_test.gleam`) - 13 tests

**Main function tested**: `lexer.lex(source: String) -> Result(List(Token), LexError)`

**Purpose**: Verify that the lexical analyzer correctly converts source code into token streams.

**Test Coverage**:
- **Empty input handling**: Ensures lexer handles empty strings gracefully
- **Simple return statements**: Basic tokenization of `return 42;`
- **Complete function definitions**: Full C function syntax parsing
- **Whitespace handling**: Proper handling of spaces, tabs, and newlines
- **Token type coverage**:
  - Identifiers (`main`, `foo`, `test123`)
  - Keywords (`int`, `return`, `void`)
  - Integer literals (`0`, `42`, `999`)
  - Punctuation (`()`, `{}`, `;`)
- **Error scenarios**: Invalid characters that should cause lexer failures

**Key Test Functions**:
- `lex_empty_input_test()` - Handles empty input
- `lex_function_definition_test()` - Complete function tokenization
- `lex_with_whitespace_test()` - Whitespace normalization
- `lex_error_invalid_character_test()` - Error handling

### 2. Parser Tests (`parser_test.gleam`) - 17 tests

**Main function tested**: `parser.parse(tokens: List(Token)) -> Result(Program, ParseError)`

**Purpose**: Verify that the syntax analyzer correctly converts token streams into Abstract Syntax Trees (AST).

**Test Coverage**:
- **Valid function parsing**: Different function names and return values
- **AST structure verification**: Correct Program/Function/Statement hierarchy
- **Comprehensive error handling**:
  - Missing tokens (return type, function name, parentheses, braces, semicolons)
  - Unexpected tokens in token stream
  - Premature input termination
  - Extra tokens after valid programs

**Key Test Functions**:
- `parse_simple_function_test()` - Basic function parsing
- `parse_function_with_different_name_test()` - Function name variations
- `parse_error_missing_semicolon_test()` - Syntax error detection
- `parse_error_unexpected_token_test()` - Invalid token handling

### 3. Codegen Tests (`codegen_test.gleam`) - 11 tests

**Main function tested**: `codegen.generate(program: Program) -> Assembly`

**Purpose**: Verify that the code generator correctly transforms AST into assembly instructions.

**Test Coverage**:
- **Basic code generation**: Simple functions with return statements
- **Function name preservation**: Ensures function names are maintained
- **Value handling**: Different integer values including negative numbers
- **Assembly structure validation**:
  - Correct instruction sequences (MOV + RET)
  - Proper operand types (Immediate values, Register targets)
  - Instruction count verification

**Key Test Functions**:
- `generate_simple_function_test()` - Basic code generation
- `generate_function_with_negative_number_test()` - Negative value handling
- `generate_preserves_function_name_test()` - Name preservation
- `generate_mov_targets_register_test()` - Assembly structure verification

### 4. Emitter Tests (`emitter_test.gleam`) - 8 tests

**Main function tested**: `emitter.emit(filename: String, assembly: Assembly, platform: Platform) -> Result(Nil, String)`

**Purpose**: Verify that the assembly emitter correctly writes platform-specific assembly files.

**Test Coverage**:
- **File creation**: Successful assembly file generation
- **Content verification**: Generated assembly contains expected elements
- **Platform support**: Both Linux and OSX platforms
- **File operations**:
  - Overwriting existing files
  - Proper file extensions (`.s`)
  - Content accuracy for different assembly inputs

**Key Test Functions**:
- `emit_simple_assembly_test()` - Basic file emission
- `emit_creates_file_with_content_test()` - Content verification
- `emit_macos_platform_test()` - Platform-specific generation
- `emit_overwrites_existing_file_test()` - File handling behavior

### 5. Compiler Tests (`compiler_test.gleam`) - 17 tests

**Main function tested**: `compiler.compile(stage: Stage, src_file: String, platform: Platform) -> Result(Nil, CompileError)`

**Purpose**: Verify end-to-end compilation pipeline and stage-specific compilation stops.

**Test Coverage**:
- **All compilation stages**:
  - `Lex`: Stop after tokenization
  - `Parse`: Stop after AST generation
  - `Codegen`: Stop after assembly generation
  - `Assembly`: Generate assembly files
  - `Executable`: Complete compilation
- **Platform testing**: Linux and OSX support
- **Error scenarios**:
  - File not found errors
  - Lexical analysis errors
  - Syntax parsing errors
- **Real file I/O**: Actual file operations with proper cleanup
- **Integration testing**: Verifies entire pipeline works together

**Key Test Functions**:
- `compile_lex_stage_valid_source_test()` - Lexical analysis stage
- `compile_assembly_stage_valid_source_test()` - Assembly generation
- `compile_file_not_found_error_test()` - Error handling
- `compile_different_function_names_test()` - End-to-end validation

## Test Quality Features

### 1. Comprehensive Error Testing
Each stage includes both happy path and error scenarios to ensure robust error handling:
- **Lexer**: Invalid characters, malformed tokens
- **Parser**: Syntax errors, missing elements, unexpected tokens
- **Compiler**: File I/O errors, compilation stage failures

### 2. Real File I/O Operations
Compiler and emitter tests use actual file operations:
- Create temporary test files with source code
- Write and read assembly output files
- Proper cleanup of temporary files after test execution
- Verify file contents match expected assembly output

### 3. Edge Case Coverage
Tests include various edge cases:
- Empty inputs and whitespace-only files
- Large numbers and negative values
- Different function names and platforms
- Multiple compilation stages on the same file

### 4. Integration Testing
Compiler tests verify the entire pipeline:
- Source code → Tokens → AST → Assembly → File output
- Cross-stage error propagation
- Platform-specific code generation

### 5. Proper Test Isolation
Each test file focuses on a single compiler stage:
- Independent testing of each main function
- Clear separation of concerns
- Minimal dependencies between test files

## Test Execution

### Running All Tests
```bash
gleam test
```

### Test Results
```
128 tests, no failures
```

All tests pass successfully, demonstrating:
- Each compiler stage's main function works correctly
- Error handling is robust across all stages
- Integration between stages is solid
- File I/O operations are reliable
- Platform-specific code generation works properly

## Testing Strategies Used

### 1. Stage Isolation
Each test file focuses on one compiler stage, enabling:
- Independent debugging of compiler components
- Clear identification of failure points
- Focused testing of specific functionality

### 2. Data-Driven Testing
Multiple test cases with different inputs per function:
- Various function names, return values, and syntax variations
- Different error conditions and edge cases
- Multiple platform configurations

### 3. Error Path Coverage
Testing both success and failure scenarios:
- Valid inputs producing expected outputs
- Invalid inputs generating appropriate errors
- Boundary conditions and edge cases

### 4. Real Environment Testing
Using actual files for I/O operations:
- Tests interact with the filesystem
- Verifies real-world usage patterns
- Ensures proper file handling and cleanup

### 5. Assertion Variety
Using appropriate assertions for different data types:
- Token lists for lexer output
- AST structures for parser output
- Assembly instructions for codegen output
- File existence and contents for emitter output

## Maintenance Guidelines

### Adding New Tests
When adding new compiler features:
1. Add unit tests to the appropriate stage test file
2. Update integration tests in `compiler_test.gleam`
3. Add test function exports to `nqcc_test.gleam`
4. Update this documentation

### Test File Naming
Follow the established pattern:
- `{stage}_test.gleam` for stage-specific tests
- `{functionality}_{scenario}_test()` for test functions

### Cleanup Requirements
All tests that create files must:
- Clean up temporary files in both success and failure cases
- Use unique file names to avoid conflicts
- Delete files using `simplifile.delete()`

## Benefits for Development

This comprehensive test suite provides:

### 1. Regression Testing
- Prevents introduction of bugs during development
- Ensures existing functionality continues to work
- Validates that changes don't break unrelated components

### 2. Debugging Support
- Isolates problems to specific compiler stages
- Provides reproducible test cases for investigation
- Enables focused fixing of individual components

### 3. Development Confidence
- Safe refactoring with immediate feedback
- Validation of new features against existing functionality
- Clear indication when changes affect compiler behavior

### 4. Documentation Through Examples
- Executable examples of expected behavior
- Clear demonstration of error conditions
- Specification of input/output relationships

### 5. Future Development Foundation
- Solid base for adding new language features
- Established patterns for testing new functionality
- Comprehensive coverage of existing features

This test suite represents a robust foundation for continued development and maintenance of the NQCC compiler, ensuring reliability and correctness throughout the development lifecycle.