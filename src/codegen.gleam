import assembly
import ast

/// Main entry point for code generation - transforms AST to assembly representation
///
/// Code generation philosophy:
/// - Direct translation from high-level AST to low-level assembly instructions
/// - Single-pass generation (no optimization phase in this simple compiler)
/// - Target-independent assembly generation (platform specifics handled in emitter)
/// - Straightforward mapping from language constructs to machine operations
///
/// Translation strategy:
/// - Program → Assembly: One-to-one mapping of program structure
/// - Functions are preserved as assembly functions with same names
/// - Statements become sequences of assembly instructions
/// - Expressions become operands (immediates, registers, memory references)
///
/// Why this approach:
/// - Keeps code generation simple and understandable
/// - Separates concerns: codegen creates abstract assembly, emitter handles platform details
/// - Makes debugging easier (clear correspondence between AST and assembly)
/// - Follows standard compiler architecture (AST → IR → Assembly)
/// - Extensible: easy to add more language constructs and assembly patterns
pub fn generate(program: ast.Program) -> assembly.Assembly {
  case program {
    ast.Program(func_def) -> assembly.Program(convert_function(func_def))
  }
}

/// Convert AST function definition to assembly function definition
///
/// Function translation strategy:
/// - Preserve function name for linking and debugging
/// - Convert function body (statement) to instruction sequence
/// - Handle function prologue/epilogue through individual instructions
/// - Map high-level function concept to assembly function structure
///
/// Assembly function structure:
/// - Function name becomes assembly label
/// - Function body becomes list of assembly instructions
/// - Return statement generates mov + ret instruction sequence
/// - Stack management handled by individual instructions, not function wrapper
///
/// Why this design:
/// - Direct mapping preserves semantic meaning across representations
/// - Function names enable proper linking and symbol resolution
/// - Instruction list format allows flexible code generation patterns
/// - Separates function structure from platform-specific calling conventions
/// - Enables easy extension for multiple statements, parameters, local variables
fn convert_function(
  func_def: ast.FunctionDefinition,
) -> assembly.FunctionDefinition {
  case func_def {
    ast.Function(name, body) -> {
      let instructions = convert_statement(body)
      assembly.Function(name, instructions)
    }
  }
}

/// Convert AST statement to sequence of assembly instructions
///
/// Statement translation patterns:
/// - Return statement: evaluate expression → move to return register → return instruction
/// - Each statement type maps to specific instruction patterns
/// - Maintains execution semantics while lowering abstraction level
/// - Handles side effects and control flow through instruction sequencing
///
/// Return statement implementation:
/// - Convert expression to operand (immediate value, register, or memory reference)
/// - Move result to designated return register (platform calling convention)
/// - Execute return instruction to transfer control back to caller
/// - Two-instruction sequence: MOV + RET (standard return pattern)
///
/// Why instruction sequences:
/// - Complex statements may require multiple machine instructions
/// - Allows optimization of instruction selection and ordering
/// - Separates semantic actions from instruction encoding
/// - Enables future optimizations (instruction scheduling, peephole optimization)
/// - Matches standard code generation practice in production compilers
fn convert_statement(statement: ast.Statement) -> List(assembly.Instruction) {
  case statement {
    ast.Return(expr) -> {
      let operand = convert_expression(expr)
      [assembly.Mov(operand, assembly.Register), assembly.Ret]
    }
  }
}

/// Convert AST expression to assembly operand for use in instructions
///
/// Expression evaluation strategy:
/// - Simple expressions (constants) become immediate operands
/// - Complex expressions would generate temporary values and registers
/// - Result represents "how to access this value" in assembly instructions
/// - Operands abstract platform-specific addressing modes and formats
///
/// Operand types and usage:
/// - Immediate operands (Imm): literal constants embedded in instructions
/// - Register operands: values stored in CPU registers
/// - Memory operands: values stored in RAM (not implemented in simple compiler)
/// - Each operand type has different performance and encoding characteristics
///
/// Current implementation (constants only):
/// - Integer literals become immediate operands for direct instruction encoding
/// - No register allocation needed for simple constant expressions
/// - Efficient: constants encoded directly in instruction stream
/// - Foundation for more complex expression evaluation (variables, arithmetic, calls)
///
/// Why operand abstraction:
/// - Separates expression semantics from instruction encoding details
/// - Enables different addressing modes without changing expression logic
/// - Platform-independent representation (x86 vs ARM vs RISC-V differences handled later)
/// - Supports future register allocation and optimization passes
/// - Standard compiler design pattern: expressions → operands → machine code
fn convert_expression(expr: ast.Expression) -> assembly.Operand {
  case expr {
    ast.Constant(i) -> assembly.Imm(i)
  }
}
