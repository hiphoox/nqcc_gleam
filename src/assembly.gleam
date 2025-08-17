/// Assembly operand representation - abstraction for instruction operands
///
/// Operand design philosophy:
/// - Abstract representation of values that can be used in assembly instructions
/// - Platform-independent operand types that map to concrete addressing modes
/// - Separates operand semantics from platform-specific encoding details
/// - Foundation for register allocation and instruction selection
///
/// Operand types and characteristics:
/// - Imm(Int): Immediate operands (literal constants embedded in instructions)
///   * Efficient: no memory access required, value encoded in instruction
///   * Limited range: typically 32-bit signed integers in most architectures
///   * Common usage: constants, small literals, enum values
/// - Register: CPU register operands (values stored in processor registers)
///   * Fast access: fastest storage location in processor hierarchy
///   * Limited quantity: small number of registers available (8-16 general purpose)
///   * Common usage: temporary values, function parameters, return values
///
/// Missing operand types (future extensions):
/// - Memory operands: values stored in RAM with various addressing modes
/// - Stack operands: values on function call stack (locals, parameters)
/// - Global operands: statically allocated global variables
///
/// Why this abstraction:
/// - Enables platform-independent code generation
/// - Supports future register allocation algorithms
/// - Allows instruction selection without knowing target architecture details
/// - Standard intermediate representation pattern in compiler design
pub type Operand {
  Imm(Int)
  Register
}

/// Assembly instruction representation - abstract machine instructions
///
/// Instruction design strategy:
/// - Platform-independent instruction set for code generation
/// - Simple, orthogonal instruction set focusing on essential operations
/// - Maps cleanly to most target architectures (x86, ARM, RISC-V)
/// - Separates instruction semantics from encoding and syntax details
///
/// Current instruction set:
/// - Mov(source, destination): Data movement between operands
///   * Fundamental operation: copies value from source to destination
///   * Used for: assignment, parameter passing, register allocation
///   * Maps to: mov (x86), mov (ARM), addi (RISC-V with zero)
///   * Operand flexibility: immediate-to-register, register-to-register, etc.
/// - Ret: Function return instruction
///   * Control flow: transfer execution back to function caller
///   * Implicit: uses link register or stack return address
///   * Maps to: ret (x86), bx lr (ARM), jalr x0, x1, 0 (RISC-V)
///   * Stack management: assumes proper stack frame cleanup
///
/// Missing instructions (future language features):
/// - Arithmetic: add, sub, mul, div for expression evaluation
/// - Control flow: jmp, cmp, conditional branches for if/while/for
/// - Memory: load, store for variable access and arrays
/// - Function calls: call for function invocation
/// - Stack operations: push, pop for local variable management
///
/// Why this minimal instruction set:
/// - Focuses on essential compiler functionality (return statements)
/// - Easy to understand and implement for educational purposes
/// - Foundation for incremental language feature addition
/// - Demonstrates core principles without overwhelming complexity
/// - Maps well to real assembly instruction sets
pub type Instruction {
  Mov(Operand, Operand)
  Ret
}

/// Assembly function definition - represents compiled function in assembly form
///
/// Function representation strategy:
/// - Bridge between high-level function concepts and low-level assembly
/// - Preserves function identity through name for linking and debugging
/// - Linear instruction sequence represents function body execution
/// - Platform-independent representation before final assembly emission
///
/// Function components:
/// - name: String - function identifier for symbol table and linking
///   * Preserved from source code for debugging and linking
///   * Used by linker to resolve function calls between object files
///   * Becomes assembly label in final output (may be name-mangled)
///   * Critical for interoperability with C standard library
/// - instructions: List(Instruction) - ordered sequence of assembly operations
///   * Linear execution model: instructions execute in sequential order
///   * Control flow handled by explicit jump instructions (future extension)
///   * Each instruction represents atomic operation at machine level
///   * List structure enables instruction optimization and analysis
///
/// Assembly function characteristics:
/// - No explicit parameters: simple functions only (current limitation)
/// - No local variables: register-only computation (current limitation)
/// - Single basic block: no control flow within function (current limitation)
/// - Standard calling convention: integrates with C ABI for system calls
///
/// Future extensions:
/// - Function parameters and local variables
/// - Multiple basic blocks for control flow (if, while, for)
/// - Function calls and recursion support
/// - Stack frame management for local storage
/// - Exception handling and cleanup code
///
/// Why this design:
/// - Simple enough to understand and implement correctly
/// - Foundation for more complex function features
/// - Matches real assembly function structure
/// - Enables standard linking and debugging workflows
/// - Preserves semantic meaning from source to assembly
pub type FunctionDefinition {
  Function(name: String, instructions: List(Instruction))
}

/// Complete assembly program representation - top-level compilation unit
///
/// Program structure design:
/// - Represents entire compilation unit in assembly intermediate form
/// - Single-function programs for simplicity (current C subset limitation)
/// - Platform-independent assembly ready for target-specific emission
/// - Final stage before concrete assembly text generation
///
/// Program composition:
/// - Program(FunctionDefinition): Single function per compilation unit
///   * Matches current language subset: simple C programs with one function
///   * Contains complete executable logic for the program
///   * Ready for assembly emission and linking into executable
///   * Foundation for multi-function programs in future
///
/// Assembly program lifecycle:
/// 1. Code generation: AST → Assembly (codegen.gleam)
/// 2. Assembly emission: Assembly → text (emitter.gleam)
/// 3. System assembly: text → object file (external gcc/clang)
/// 4. Linking: object file → executable (external ld/gcc)
///
/// Current limitations (future extensions):
/// - Single function per program (no multiple function definitions)
/// - No global variables or static data sections
/// - No external function declarations or imports
/// - No data segments or initialized data
/// - No preprocessor directives or inline assembly
///
/// Why single-function design:
/// - Simplifies compiler implementation for educational purposes
/// - Focuses on core compilation concepts without complex linking
/// - Sufficient for demonstrating complete compilation pipeline
/// - Foundation for multi-function and multi-file compilation
/// - Matches typical "hello world" and simple program structure
///
/// Integration with toolchain:
/// - Generated assembly integrates with standard system tools
/// - Can be linked with C standard library functions
/// - Supports standard debugging symbols and formats
/// - Compatible with existing build systems and IDEs
/// - Enables interoperability with existing C codebases
pub type Assembly {
  Program(FunctionDefinition)
}
