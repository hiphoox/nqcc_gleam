# NQCC Source Code Documentation

This directory contains the complete source code for the NQCC (Not Quite C Compiler) implementation in Gleam. The compiler follows a traditional multi-stage architecture with clear separation of concerns between each compilation phase.

## 📁 Module Overview

```
src/
├── nqcc.gleam          # Main entry point and compilation driver
├── cli.gleam           # Command-line interface and argument parsing
├── compiler.gleam      # Core compilation pipeline orchestration
├── lexer.gleam         # Lexical analysis (source → tokens)
├── parser.gleam        # Syntax analysis (tokens → AST)
├── codegen.gleam       # Code generation (AST → assembly)
├── emitter.gleam       # Assembly emission (assembly → platform-specific text)
├── tokens.gleam        # Token type definitions and lexical patterns
├── ast.gleam           # Abstract Syntax Tree type definitions
├── assembly.gleam      # Assembly instruction type definitions
├── settings.gleam      # Compilation settings and platform configuration
└── utils.gleam         # Shared utility functions
```

## 🔄 Data Flow Architecture

The compiler follows a linear transformation pipeline where each stage consumes the output of the previous stage:

```
Source Code (String)
       ↓ lexer.gleam
   Tokens (List(Token))
       ↓ parser.gleam
   AST (Program)
       ↓ codegen.gleam
   Assembly (Assembly)
       ↓ emitter.gleam
   Assembly Text (String)
```

## 📋 Module Details

### 1. Entry Point and Orchestration

#### `nqcc.gleam` - Main Entry Point
**Purpose**: Application bootstrap and high-level compilation driver.

**Key Functions**:
- `main()` - Application entry point, sets up CLI
- `handle_command(Config)` - Command handler with error reporting
- `run_driver(Config)` - Main compilation pipeline orchestration
- `preprocess(String)` - C preprocessor integration
- `assemble_and_link(String, Bool)` - Final assembly and linking

**Responsibilities**:
- Application lifecycle management
- Integration with external tools (GCC preprocessor/assembler)
- Resource management and cleanup
- High-level error handling and user messaging

#### `cli.gleam` - Command-Line Interface
**Purpose**: Command-line argument parsing and configuration management.

**Key Types**:
```gleam
pub type Config {
  Config(
    stage: settings.Stage,
    platform: settings.Platform,
    debug: Bool,
    src_file: String,
  )
}
```

**Key Functions**:
- `create_app(fn(Config) -> Nil)` - CLI application setup
- `run_app(glint.Glint(Nil))` - Execute CLI with system arguments
- `parse_config(...)` - Convert CLI flags to structured configuration

**Responsibilities**:
- Flag parsing and validation
- Help message generation
- Configuration structure creation
- CLI error handling

#### `compiler.gleam` - Compilation Pipeline
**Purpose**: Core compilation pipeline that orchestrates all compilation stages.

**Key Types**:
```gleam
pub type CompileError {
  LexError(lexer.LexError)
  ParseError(parser.ParseError)
  EmitError(String)
  IOError(String)
}
```

**Key Functions**:
- `compile(Stage, String, Platform)` - Main compilation entry point
- `compile_to_tokens(String)` - Lexical analysis stage
- `compile_to_ast(String)` - Syntax analysis stage
- `compile_to_asm(String)` - Code generation stage

**Responsibilities**:
- Stage-based compilation control
- Error type unification across stages
- Pipeline composition and data flow
- Early exit for debugging stages

### 2. Compilation Stages

#### `lexer.gleam` - Lexical Analysis
**Purpose**: Convert source code strings into structured token sequences.

**Key Types**:
```gleam
pub type LexError {
  LexError(String)
}

pub type MatchDef {
  MatchDef(matched_substring: String, matching_token: TokenDef)
}
```

**Key Functions**:
- `lex(String)` - Main lexical analysis entry point
- `lex_recursive(String, List(TokenDef))` - Core recursive lexing algorithm
- `token_defs()` - Token pattern definitions

**Algorithm**:
1. Initialize regex-based token definitions
2. Recursively match patterns at current position
3. Use longest-match disambiguation for overlapping patterns
4. Convert matched text to appropriate token types
5. Handle whitespace and advance through input

**Responsibilities**:
- Pattern matching with regular expressions
- Keyword vs identifier disambiguation
- Whitespace handling and normalization
- Lexical error detection and reporting

#### `parser.gleam` - Syntax Analysis
**Purpose**: Convert token streams into Abstract Syntax Trees (AST).

**Key Types**:
```gleam
pub type ParseError {
  ParseError(String)
  UnexpectedEndOfInput
}

pub type TokenStream {
  TokenStream(tokens: List(Token), position: Int)
}
```

**Key Functions**:
- `parse(List(Token))` - Main parsing entry point
- `parse_program(TokenStream)` - Top-level program parsing
- `parse_function_definition(TokenStream)` - Function parsing
- `parse_statement(TokenStream)` - Statement parsing
- `parse_expression(TokenStream)` - Expression parsing

**Algorithm**:
- Recursive descent parser matching C grammar subset
- Top-down parsing with explicit lookahead
- Immutable token stream with position tracking
- Comprehensive error reporting with context

**Responsibilities**:
- Grammar rule enforcement
- AST node construction
- Syntax error detection and reporting
- Token consumption and stream management

#### `codegen.gleam` - Code Generation
**Purpose**: Transform Abstract Syntax Trees into assembly instruction sequences.

**Key Functions**:
- `generate(ast.Program)` - Main code generation entry point
- `convert_function(ast.FunctionDefinition)` - Function code generation
- `convert_statement(ast.Statement)` - Statement code generation
- `convert_expression(ast.Expression)` - Expression code generation

**Code Generation Strategy**:
- Direct AST-to-assembly translation
- Single-pass generation (no optimization)
- Platform-independent abstract assembly
- Simple instruction patterns (MOV + RET for returns)

**Responsibilities**:
- AST traversal and transformation
- Instruction sequence generation
- Operand type selection (immediate vs register)
- Abstract assembly construction

#### `emitter.gleam` - Assembly Emission
**Purpose**: Convert abstract assembly into platform-specific assembly text files.

**Key Functions**:
- `emit(String, assembly.Assembly, settings.Platform)` - Main emission entry point
- Platform-specific assembly formatting functions

**Platform Differences Handled**:
- **Linux**: ELF object format, GNU assembler syntax
- **macOS**: Mach-O object format, function name prefixing

**Responsibilities**:
- Platform-specific syntax generation
- Assembly directive insertion
- File I/O operations
- Integration with system assembler tools

### 3. Type Definitions

#### `tokens.gleam` - Token Types
**Purpose**: Define all lexical units recognized by the compiler.

**Key Types**:
```gleam
pub type Token {
  Identifier(String)
  Constant(Int)
  KWInt
  KWReturn
  KWVoid
  OpenParen
  CloseParen
  OpenBrace
  CloseBrace
  Semicolon
}

pub type TokenDef {
  TokenDef(re: regexp.Regexp, converter: fn(String) -> Token)
}
```

**Design Principles**:
- Each token represents exactly one lexical unit
- Data-carrying tokens preserve source information
- Extensible design for adding new token types
- Regex-based pattern matching with conversion functions

#### `ast.gleam` - Abstract Syntax Tree
**Purpose**: Define the structural representation of parsed C programs.

**Key Types**:
```gleam
pub type Expression {
  Constant(Int)
}

pub type Statement {
  Return(Expression)
}

pub type FunctionDefinition {
  Function(name: String, body: Statement)
}

pub type Program {
  Program(FunctionDefinition)
}
```

**Design Principles**:
- Hierarchical structure reflecting language grammar
- Type safety ensuring valid program structure
- Minimal but complete representation
- Foundation for future language extensions

#### `assembly.gleam` - Assembly Instructions
**Purpose**: Define abstract assembly instruction representation.

**Key Types**:
```gleam
pub type Operand {
  Imm(Int)
  Register
}

pub type Instruction {
  Mov(Operand, Operand)
  Ret
}

pub type Assembly {
  Program(FunctionDefinition)
}
```

**Design Principles**:
- Platform-independent instruction representation
- Simple operand model (immediate values and registers)
- Extensible for additional instruction types
- Clean mapping to target architectures

#### `settings.gleam` - Configuration Types
**Purpose**: Define compilation configuration and platform settings.

**Key Types**:
```gleam
pub type Stage {
  Lex
  Parse
  Codegen
  Assembly
  Executable
}

pub type Platform {
  OSX
  Linux
}
```

**Design Principles**:
- Explicit compilation stage enumeration
- Platform abstraction for cross-compilation
- Type-safe configuration management
- Clear separation of compilation concerns

### 4. Utilities

#### `utils.gleam` - Shared Utilities
**Purpose**: Provide common functionality used across multiple modules.

**Key Functions**:
- File extension validation and manipulation
- External command execution
- Resource cleanup with debug mode support
- String processing utilities

**Responsibilities**:
- Cross-module utility functions
- File system operations
- Process management
- Resource lifecycle management

## 🔧 Extension Points

### Adding New Language Features

1. **New Token Types**:
   - Add variants to `Token` type in `tokens.gleam`
   - Add corresponding `TokenDef` entries with regex patterns
   - Update lexer test cases

2. **New AST Nodes**:
   - Extend AST types in `ast.gleam`
   - Update parser functions to handle new syntax
   - Add parser test cases

3. **New Instructions**:
   - Add instruction variants to `assembly.gleam`
   - Update code generation patterns in `codegen.gleam`
   - Extend emitter for platform-specific syntax

4. **New Platforms**:
   - Add platform variant to `settings.gleam`
   - Implement platform-specific logic in `emitter.gleam`
   - Add CLI support and test cases

### Architecture Guidelines

1. **Separation of Concerns**: Each module has a single, well-defined responsibility
2. **Type Safety**: Use Gleam's type system to prevent invalid states
3. **Error Handling**: Explicit error types and Result propagation
4. **Immutability**: Functional programming principles throughout
5. **Testability**: Pure functions with clear input/output relationships

### Common Patterns

1. **Result Chaining**: Use `use` syntax for error propagation
2. **Type Constructors**: Pattern matching for type dispatch
3. **Configuration Passing**: Thread configuration through call chains
4. **Resource Management**: Automatic cleanup with `with_cleanup` pattern

## 🧪 Testing Strategy

Each module includes comprehensive unit tests:
- **Isolated Testing**: Test each module's public interface independently
- **Error Coverage**: Test both success and failure scenarios
- **Edge Cases**: Handle boundary conditions and invalid inputs
- **Integration**: Verify module interactions work correctly

## 📚 Further Reading

- **Gleam Language Guide**: https://gleam.run/book/
- **Writing a C Compiler**: https://norasandler.com/book/
- **Engineering a Compiler**: https://www.educate.elsevier.com/book/details/9780128154120
- **Crafting Interpreters**: https://craftinginterpreters.com/
- **Type System Benefits**: https://daily.dev/blog/gleam-the-new-programming-language-for-building-typesafe-systems
- **Functional Architecture**: https://ricofritzsche.me/pure-functions-and-immutable-data-simplifying-complexity-by-design/
- **Automation Testing Benefits**: https://www.telerik.com/blogs/5-benefits-automated-testing-why-important

This source code demonstrates a clean, functional approach to compiler construction, leveraging Gleam's strengths while maintaining clarity and extensibility.
