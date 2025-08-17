# NQCC - A C Compiler in Gleam

![Gleam](https://img.shields.io/badge/gleam-%23ffaff3.svg?style=for-the-badge&logo=gleam&logoColor=white)
![Assembly](https://img.shields.io/badge/assembly-%23525252.svg?style=for-the-badge&logo=assemblyscript&logoColor=white)

A Gleam implementation of a C compiler based on the book "Writing a C Compiler" by Nora Sandler. This implementation tries to be very close to the [OCaml implementation](https://github.com/nlsandler/nqcc2). This compiler translates a subset of C to x86-64 assembly for Linux and macOS platforms.

## 🚀 Features

- **Lexical Analysis**: Tokenizes C source code into identifiers, constants, keywords, and punctuation
- **Syntax Analysis**: Builds Abstract Syntax Trees (AST) from token streams
- **Code Generation**: Converts AST to x86-64 assembly instructions
- **Assembly Emission**: Outputs platform-specific assembly code for Linux and macOS
- **Multi-stage Compilation**: Stop at any compilation stage for debugging
- **Cross-platform**: Supports both Linux and macOS targets

## 📋 Current Language Support

This implementation currently supports a minimal but complete subset of C:

### ✅ Supported Features
- Function definitions with `int` return type
- `void` parameter lists: `int main(void)`
- Return statements with integer constants
- Integer literals (positive and negative)
- Basic C keywords: `int`, `return`, `void`
- Standard C punctuation: `()`, `{}`, `;`

### ❌ Not Yet Supported
- Variables and expressions
- Function parameters
- Control flow (`if`, `while`, `for`)
- Arithmetic operations
- Multiple functions
- Standard library functions

### 📝 Example Program
```c
int main(void) {
    return 42;
}
```

## 📁 Project Structure

```
nqcc_gleam/
├── src/                    # Source code
│   ├── nqcc.gleam         # Main entry point
│   ├── cli.gleam          # Command-line interface
│   ├── compiler.gleam     # Main compilation pipeline
│   ├── lexer.gleam        # Lexical analysis (source → tokens)
│   ├── parser.gleam       # Syntax analysis (tokens → AST)
│   ├── codegen.gleam      # Code generation (AST → assembly)
│   ├── emitter.gleam      # Assembly emission (assembly → file)
│   ├── tokens.gleam       # Token type definitions
│   ├── ast.gleam          # Abstract Syntax Tree types
│   ├── assembly.gleam     # Assembly instruction types
│   ├── settings.gleam     # Configuration and platform types
│   └── utils.gleam        # Utility functions
├── test/                   # Comprehensive test suite
│   ├── lexer_test.gleam   # Lexer unit tests
│   ├── parser_test.gleam  # Parser unit tests
│   ├── codegen_test.gleam # Code generator unit tests
│   ├── emitter_test.gleam # Assembly emitter unit tests
│   ├── compiler_test.gleam # Integration tests
│   ├── nqcc_test.gleam    # Test runner
│   └── README.md          # Test documentation
├── sample/                 # Example programs
│   └── test_program.c     # Simple test program
├── .github/               # GitHub workflows
├── build/                 # Build artifacts
├── gleam.toml            # Project configuration
└── README.md             # This file
```

## 🛠️ Installation

### Prerequisites
- [Gleam](https://gleam.run/getting-started/installing/) (latest version)
- [Erlang/OTP](https://www.erlang.org/downloads) (version 24+)
- GCC or Clang (for preprocessing, assembling, and linking)

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd nqcc_gleam

# Install dependencies
gleam deps download

# Build the project
gleam build

# Run tests to verify installation
gleam test
```

### Creating Standalone Executable
```bash
# Create escript executable using gleescript
gleam run -m gleescript

# Or export as Erlang shipment for distribution
gleam export erlang-shipment

# Run the standalone executable (after gleam run -m gleescript)
./nqcc --help

# Or run from erlang-shipment
cd build/erlang-shipment
./entrypoint.sh run --help
```

#### Standalone Executable Methods

**Method 1: Escript (`gleam run -m gleescript`)**
- Creates a single `nqcc` executable file in the project root
- Requires Erlang on target system
- Direct executable: `./nqcc hello.c`
- Smaller footprint, easier to distribute

**Method 2: Erlang Shipment (`gleam export erlang-shipment`)**
- Creates a `build/erlang-shipment` directory with runtime
- Requires Erlang on target system
- Run via entrypoint: `./entrypoint.sh run hello.c`
- Full runtime package, better for complex deployments

## 🎯 Usage

### Basic Compilation
```bash
# Compile and create executable
gleam run hello.c

# This creates hello.s (assembly) and hello (executable)
```

### Command-Line Options

```bash
gleam run [OPTIONS] <source-file.c>
```

#### Compilation Stage Flags
- `--lex` - Run lexer only (tokenization)
- `--parse` - Run lexer and parser only (AST generation)
- `--codegen` - Run through code generation (stop before assembly emission)
- `-s` - Generate assembly file only (don't create executable)
- (no flag) - Complete compilation to executable

#### Platform Flags
- `--target linux` - Generate Linux-compatible assembly (default: osx)
- `--target osx` - Generate macOS-compatible assembly

#### Debug Flags
- `-d` - Debug mode (preserve intermediate files)

#### Help
- `--help` - Show usage information

### 📚 Examples

#### 1. Complete Compilation
```bash
# Create a simple C program
echo 'int main(void) { return 42; }' > hello.c

# Compile to executable
gleam run hello.c

# Run the program
./hello
echo $?  # Prints: 42
```

#### 2. Stop at Different Stages
```bash
# Lexical analysis only
gleam run --lex hello.c

# Parse to AST only
gleam run --parse hello.c

# Generate assembly only
gleam run -s hello.c
cat hello.s  # View generated assembly
```

#### 3. Cross-platform Compilation
```bash
# Generate Linux assembly on macOS
gleam run --target linux -s hello.c

# Generate macOS assembly
gleam run --target osx -s hello.c
```

#### 4. Debug Mode
```bash
# Keep all intermediate files
gleam run -d hello.c
ls hello.*  # Shows: hello.c, hello.i, hello.s, hello
```

## 🔄 Compilation Pipeline

The compiler follows a traditional multi-stage compilation pipeline:

```
Source Code (.c)
       ↓
   Preprocessing (.i)     # GCC preprocessor
       ↓
   Lexical Analysis       # Tokenization
       ↓
   Syntax Analysis        # AST generation
       ↓
   Code Generation        # Assembly generation
       ↓
   Assembly Emission (.s) # Platform-specific output
       ↓
   Assembly & Linking     # GCC assembler/linker
       ↓
   Executable
```

### Stage Details

1. **Preprocessing**: Uses GCC to handle `#include` and macros
2. **Lexical Analysis**: Converts source text into tokens
3. **Syntax Analysis**: Builds Abstract Syntax Tree from tokens
4. **Code Generation**: Converts AST to abstract assembly
5. **Assembly Emission**: Generates platform-specific assembly text
6. **Assembly & Linking**: Uses GCC to create executable

## 🧪 Testing

### Run All Tests
```bash
gleam test
```

### Test Coverage
The project includes comprehensive unit tests with 128 test cases covering:

- **Lexer Tests**: Token generation, whitespace handling, error cases
- **Parser Tests**: AST construction, syntax error detection
- **Codegen Tests**: Assembly instruction generation
- **Emitter Tests**: Platform-specific assembly output
- **Integration Tests**: End-to-end compilation pipeline

### Test Documentation
See [`test/README.md`](test/README.md) for detailed test documentation.

## 🏗️ Architecture

### Core Components

1. **Lexer** (`lexer.gleam`)
   - Converts source code strings to token lists
   - Handles whitespace, keywords, identifiers, and literals
   - Regex-based pattern matching with longest-match disambiguation

2. **Parser** (`parser.gleam`)
   - Converts token streams to Abstract Syntax Trees
   - Recursive descent parser for C grammar subset
   - Comprehensive error reporting for syntax issues

3. **Code Generator** (`codegen.gleam`)
   - Transforms AST to abstract assembly instructions
   - Platform-independent instruction generation
   - Simple instruction sequences (MOV + RET for returns)

4. **Emitter** (`emitter.gleam`)
   - Converts abstract assembly to platform-specific text
   - Handles Linux vs macOS assembly syntax differences
   - Generates GNU assembler compatible output

5. **Compiler** (`compiler.gleam`)
   - Orchestrates the entire compilation pipeline
   - Manages intermediate files and cleanup
   - Integrates with external tools (GCC for preprocessing/linking)

### Type System

The compiler uses Gleam's strong type system to ensure correctness:

- **Token**: Lexical units (keywords, identifiers, literals, punctuation)
- **AST**: Abstract syntax tree nodes (programs, functions, statements, expressions)
- **Assembly**: Abstract assembly instructions (MOV, RET with operands)
- **Settings**: Compilation configuration (stages, platforms)

## 🚧 Development

### Adding New Features

1. **Language Features**: Extend AST types and update parser
2. **Instructions**: Add new assembly instruction types
3. **Platforms**: Extend emitter for new target platforms
4. **Optimizations**: Modify code generator for better output

### Code Style

- Follow Gleam conventions and formatting
- Use descriptive variable names and comprehensive documentation
- Include unit tests for all new functionality
- Maintain separation of concerns between compilation stages

### Debugging

Use the debug flag and stage flags for troubleshooting:

```bash
# Debug lexer issues
gleam run --lex -d problematic.c

# Debug parser issues
gleam run --parse -d problematic.c

# Inspect generated assembly
gleam run -s -d working.c
cat working.s
```

## 📖 References

- **Book**: ["Writing a C Compiler" by Nora Sandler](https://norasandler.com/book/)
- **Language**: [Gleam Language Guide](https://gleam.run/book/)
- **Platform**: [Erlang/OTP Documentation](https://www.erlang.org/doc/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass: `gleam test`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Nora Sandler for the excellent "Writing a C Compiler" book
- The Gleam community for the fantastic language and ecosystem
- Contributors to the Gleam standard library and tooling
