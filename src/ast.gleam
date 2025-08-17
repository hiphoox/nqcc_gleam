/// Abstract Syntax Tree expression representation - values and computations
///
/// Expression design philosophy:
/// - Represents all value-producing constructs in the source language
/// - Captures semantic meaning independent of concrete syntax
/// - Foundation for type checking, optimization, and code generation
/// - Hierarchical structure reflects expression precedence and associativity
///
/// Current expression types:
/// - Constant(Int): Integer literal expressions
///   * Represents compile-time known integer values (42, 100, -5)
///   * Simplest expression type: no computation required at runtime
///   * Foundation for constant folding optimizations
///   * Maps directly to immediate operands in assembly generation
///   * Type: always integer (future: support for floats, strings, booleans)
///
/// Missing expression types (future language features):
/// - Variable references: access to named variables and parameters
/// - Binary operations: arithmetic (+, -, *, /), comparison (<, >, ==)
/// - Unary operations: negation (-x), logical not (!x)
/// - Function calls: invocation of other functions with arguments
/// - Assignment expressions: variable modification (x = y)
/// - Array access: indexing into arrays and pointers
/// - Struct member access: field selection from structures
///
/// Why start with constants only:
/// - Simplest possible expression evaluation (no runtime computation)
/// - Enables complete compilation pipeline without complex semantics
/// - Foundation for more complex expression types
/// - Demonstrates core compiler concepts without overwhelming complexity
/// - Sufficient for simple "return 42" style programs
///
/// Expression evaluation strategy:
/// - Expressions are evaluated for their values during code generation
/// - Constant expressions can be evaluated at compile time
/// - Complex expressions generate instruction sequences
/// - All expressions have types (currently: integer only)
/// - Expression trees guide instruction selection and optimization
pub type Expression {
  Constant(Int)
}

/// Abstract Syntax Tree statement representation - actions and control flow
///
/// Statement design philosophy:
/// - Represents all action-performing constructs in the source language
/// - Captures program execution flow and side effects
/// - Statements execute for their effects, not their values
/// - Sequential execution model with explicit control flow constructs
///
/// Current statement types:
/// - Return(Expression): Function return statements
///   * Terminates function execution and returns control to caller
///   * Evaluates expression and passes result as function return value
///   * Only statement type needed for simple expression-based functions
///   * Maps to mov + ret instruction sequence in code generation
///   * Required in C: all non-void functions must return a value
///
/// Missing statement types (future language features):
/// - Expression statements: evaluate expression for side effects (function calls)
/// - Variable declarations: introduce new variables with optional initialization
/// - Assignment statements: modify existing variable values
/// - Conditional statements: if-else branching based on boolean expressions
/// - Loop statements: while, for, do-while repetition constructs
/// - Block statements: compound statements with local scope
/// - Break/continue: loop control flow statements
/// - Function declarations: nested function definitions
///
/// Statement execution semantics:
/// - Statements execute in sequential order (top to bottom)
/// - Control flow statements can alter execution order
/// - Each statement may have side effects (memory modification, I/O)
/// - Statements don't produce values (unlike expressions)
/// - Function body consists of sequence of statements
///
/// Why start with return only:
/// - Minimal statement set for complete function definitions
/// - Enables end-to-end compilation without complex control flow
/// - Foundation for more sophisticated statement types
/// - Sufficient for expression-based computational functions
/// - Demonstrates statement vs expression distinction clearly
///
/// Code generation implications:
/// - Return statements generate function epilogue and return instructions
/// - Future statements will generate various instruction patterns
/// - Statement order determines instruction sequence in assembly
/// - Control flow statements generate conditional jumps and labels
pub type Statement {
  Return(Expression)
}

/// Abstract Syntax Tree function definition - complete function representation
///
/// Function definition design philosophy:
/// - Represents complete function declarations from source code
/// - Bridges high-level language concepts with low-level implementation
/// - Captures function interface and implementation in single construct
/// - Foundation for function call resolution and code generation
///
/// Function components:
/// - name: String - function identifier and symbol name
///   * Unique identifier within program scope
///   * Used for function call resolution and linking
///   * Becomes assembly label in code generation
///   * Must follow C identifier rules (letters, digits, underscore)
///   * Entry point functions typically named "main"
/// - body: Statement - function implementation
///   * Single statement representing function logic
///   * Currently: only return statements (simple expression functions)
///   * Future: compound statements with multiple operations
///   * Determines function behavior and return value
///   * Maps to instruction sequence in assembly generation
///
/// Current function limitations (future extensions):
/// - No parameters: functions take no input arguments
/// - No local variables: no variable declarations within function
/// - Single statement body: no complex control flow
/// - No return type annotation: assumes integer return type
/// - No function attributes: no inline, static, extern modifiers
///
/// Function semantics in C:
/// - Functions are first-class program units
/// - Each function has unique name in global namespace
/// - Functions can call other functions (future: recursion support)
/// - Main function serves as program entry point
/// - Functions integrate with C standard library and system calls
///
/// Why minimal function design:
/// - Focuses on essential function concepts without complexity
/// - Sufficient for complete compilation to executable programs
/// - Foundation for parameter passing and local variables
/// - Demonstrates function compilation pipeline clearly
/// - Enables integration with C toolchain and libraries
///
/// Code generation strategy:
/// - Function name becomes assembly function label
/// - Function body generates instruction sequence
/// - Calling convention handled by assembly emission
/// - Stack frame management for future parameter/local support
/// - Integration with system ABI for interoperability
pub type FunctionDefinition {
  Function(name: String, body: Statement)
}

/// Abstract Syntax Tree program representation - complete compilation unit
///
/// Program design philosophy:
/// - Represents entire source file or compilation unit
/// - Top-level construct that contains all program elements
/// - Entry point for semantic analysis and code generation
/// - Bridge between parsing and compilation phases
///
/// Program structure:
/// - Program(FunctionDefinition): Single function programs
///   * Current language subset: one function per source file
///   * Typically contains the main function as program entry point
///   * Complete executable logic contained within single function
///   * Foundation for multi-function programs in future versions
///
/// Program compilation lifecycle:
/// 1. Lexical analysis: source text → token stream
/// 2. Syntax analysis: tokens → AST Program
/// 3. Semantic analysis: AST validation and type checking (future)
/// 4. Code generation: AST → assembly representation
/// 5. Assembly emission: assembly → platform-specific text
/// 6. System toolchain: assembly → object file → executable
///
/// Current program limitations (future language features):
/// - Single function per program (no multiple function definitions)
/// - No global variable declarations
/// - No preprocessor directives (#include, #define)
/// - No external function declarations (extern)
/// - No data type definitions (struct, enum, typedef)
/// - No forward declarations or prototypes
///
/// Why single-function programs:
/// - Simplifies parser implementation and AST structure
/// - Focuses on core compilation concepts without complex linking
/// - Sufficient for demonstrating complete compilation pipeline
/// - Educational clarity: easy to understand program structure
/// - Foundation for incremental language feature addition
///
/// Program semantics:
/// - Represents complete executable program unit
/// - Contains entry point for program execution (main function)
/// - Can be compiled to standalone executable
/// - Integrates with C runtime and standard library
/// - Follows C program structure and execution model
///
/// Future program extensions:
/// - Multiple function definitions with call graph
/// - Global variable declarations and initialization
/// - Type definitions and user-defined data structures
/// - Module system and separate compilation
/// - Preprocessor support and macro expansion
/// - Standard library integration and system calls
pub type Program {
  Program(FunctionDefinition)
}
