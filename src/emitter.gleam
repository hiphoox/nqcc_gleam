import assembly
import gleam/list
import gleam/string
import settings
import simplifile

/// Assembly emission module - converts abstract assembly to platform-specific text format
///
/// Assembly emission responsibilities:
/// - Transform abstract assembly instructions into concrete assembler syntax
/// - Handle platform-specific assembler directives and calling conventions
/// - Generate proper object file metadata (sections, symbols, stack notes)
/// - Emit human-readable assembly that can be assembled by system tools (gas, nasm)
///
/// Platform abstraction strategy:
/// - Abstract assembly from codegen is platform-independent
/// - Emitter handles all platform-specific syntax and ABI differences
/// - Separate emission functions for different platforms enable clean specialization
/// - Generated assembly integrates with standard toolchains (gcc, clang, ld)
///
/// Why text-based assembly output:
/// - Integrates with existing assembler tools rather than generating object files directly
/// - Easier debugging: developers can inspect generated assembly code
/// - Leverages mature assembler implementations for optimization and error checking
/// - Standard practice in production compilers (gcc, clang emit assembly first)
/// - Enables manual assembly optimization and inspection during development
/// Main assembly emission entry point - converts abstract assembly to platform-specific file
///
/// Assembly file generation strategy:
/// - Transform abstract assembly representation into concrete assembler syntax
/// - Handle platform-specific differences in one centralized location
/// - Generate assembly file that can be processed by system assembler (gas, nasm)
/// - Provide clear error messages for file I/O failures
///
/// File output approach:
/// - Write complete assembly program as single text file
/// - Use platform-appropriate file extension (.s) and format
/// - Generate self-contained assembly that includes all necessary metadata
/// - Integration point with external assembler toolchain
///
/// Why this design:
/// - Single responsibility: only handles assembly-to-text conversion
/// - Platform abstraction: all platform differences handled in emit_assembly
/// - Error handling: file I/O failures are explicitly handled and reported
/// - Standard practice: matches gcc/clang assembly emission approach
/// - Debugging friendly: generated assembly files can be manually inspected
pub fn emit(
  assembly_file: String,
  asm: assembly.Assembly,
  platform: settings.Platform,
) -> Result(Nil, String) {
  case asm {
    assembly.Program(func_def) -> {
      let content = emit_assembly(func_def, platform)
      case simplifile.write(assembly_file, content) {
        Ok(Nil) -> Ok(Nil)
        Error(_) -> Error("Failed to write assembly file")
      }
    }
  }
}

/// Convert function definition to platform-specific assembly text
///
/// Platform-specific assembly generation strategy:
/// - Handle major differences between OSX (macOS) and Linux assembly syntax
/// - Generate proper assembler directives for each platform's toolchain
/// - Include necessary metadata for linking and debugging
/// - Follow platform calling conventions and ABI requirements
///
/// OSX (macOS) assembly characteristics:
/// - Mach-O object format with specific section directives
/// - Function names prefixed with underscore (_main vs main)
/// - Specific text section: __TEXT,__text with alignment directives
/// - Stack frame management with explicit prologue/epilogue
/// - Subsections_via_symbols directive for linker optimization
///
/// Linux assembly characteristics:
/// - ELF object format with GNU assembler syntax
/// - Standard function names without prefix
/// - Simple .globl directive for symbol export
/// - GNU stack note for non-executable stack marking
/// - More minimal assembly structure
///
/// Why platform-specific emission:
/// - Assembly syntax varies significantly between platforms
/// - Object file formats require different metadata and directives
/// - Calling conventions and ABI differ between systems
/// - Integrates with platform-standard toolchains and linkers
/// - Enables proper debugging symbol generation
fn emit_assembly(
  func_def: assembly.FunctionDefinition,
  platform: settings.Platform,
) -> String {
  case func_def {
    assembly.Function(name, instructions) -> {
      let label = show_label(name, platform)
      case platform {
        settings.OSX -> {
          let header =
            "\t.section\t__TEXT,__text,regular,pure_instructions\n\t.globl\t"
            <> label
            <> "\n\t.p2align\t4, 0x90\n"
            <> label
            <> ":\n"
          let prologue = "\tpushq\t%rbp\n\tmovq\t%rsp, %rbp\n"
          let body =
            string.join(
              list.map(instructions, fn(inst) { emit_instruction_macos(inst) }),
              "",
            )
          let epilogue = "\tpopq\t%rbp\n\tretq\n"
          let footer = ".subsections_via_symbols\n"
          header <> prologue <> body <> epilogue <> footer
        }
        settings.Linux -> {
          let header = "\n  .globl " <> label <> "\n" <> label <> ":\n"
          let body = string.join(list.map(instructions, emit_instruction), "")
          let stack_note = emit_stack_note(platform)
          header <> body <> stack_note
        }
      }
    }
  }
}

/// Convert abstract assembly instruction to Linux/GNU assembler syntax
///
/// Linux instruction emission strategy:
/// - Use GNU assembler (gas) AT&T syntax conventions
/// - Include all necessary instruction operands and addressing modes
/// - Generate proper instruction mnemonics for x86-64 architecture
/// - Handle register naming and immediate value formatting
///
/// Instruction patterns:
/// - MOV: movl source, destination (AT&T syntax: destination last)
/// - RET: ret (simple return instruction, no operands)
/// - Proper tab indentation for assembler formatting conventions
///
/// Why Linux-specific function:
/// - GNU assembler has specific syntax requirements
/// - AT&T syntax differs from Intel syntax (operand order, prefixes)
/// - Linux toolchain expects specific instruction formatting
/// - Enables integration with gcc/binutils toolchain
fn emit_instruction(instruction: assembly.Instruction) -> String {
  case instruction {
    assembly.Mov(src, dst) ->
      "\tmovl " <> show_operand(src) <> ", " <> show_operand(dst) <> "\n"
    assembly.Ret -> "\tret\n"
  }
}

/// Convert abstract assembly instruction to macOS assembler syntax
///
/// macOS instruction emission strategy:
/// - Use Apple's assembler syntax (based on GNU assembler)
/// - Handle macOS-specific instruction formatting requirements
/// - Generate instructions compatible with Xcode toolchain
/// - Manage stack frame through explicit prologue/epilogue instead of ret
///
/// Instruction patterns:
/// - MOV: movl source, destination (same AT&T syntax as Linux)
/// - RET: empty string (return handled by epilogue sequence)
/// - Stack management done in function prologue/epilogue, not individual instructions
///
/// Why macOS-specific function:
/// - Apple's assembler has subtle differences from GNU assembler
/// - Different approach to function return (prologue/epilogue vs individual ret)
/// - Integration with Apple's development toolchain and debugging tools
/// - Handles macOS-specific calling convention requirements
fn emit_instruction_macos(instruction: assembly.Instruction) -> String {
  case instruction {
    assembly.Mov(src, dst) ->
      "\tmovl "
      <> show_operand_macos(src)
      <> ", "
      <> show_operand_macos(dst)
      <> "\n"
    assembly.Ret -> ""
  }
}

/// Format assembly operand for macOS assembler syntax
///
/// macOS operand formatting strategy:
/// - Follow AT&T syntax conventions used by Apple's assembler
/// - Use percent prefix for registers (%eax, %ebx, etc.)
/// - Use dollar prefix for immediate values ($42, $100, etc.)
/// - Ensure compatibility with Apple's version of gas assembler
///
/// Operand types:
/// - Register: %eax (32-bit accumulator register for return values)
/// - Immediate: $value (literal constants embedded in instructions)
/// - Consistent with GNU assembler syntax for cross-platform compatibility
///
/// Why macOS-specific operand function:
/// - Allows for future platform-specific operand extensions
/// - Enables different register allocation strategies per platform
/// - Maintains clean separation between platform-specific code
/// - Foundation for handling macOS-specific addressing modes
fn show_operand_macos(operand: assembly.Operand) -> String {
  case operand {
    assembly.Register -> "%eax"
    assembly.Imm(i) -> "$" <> string.inspect(i)
  }
}

/// Format assembly operand for Linux/GNU assembler syntax
///
/// Linux operand formatting strategy:
/// - Use standard GNU assembler AT&T syntax conventions
/// - Consistent register naming with percent prefix (%eax, %ebx, etc.)
/// - Standard immediate value formatting with dollar prefix
/// - Compatible with binutils assembler used in Linux distributions
///
/// Operand types:
/// - Register: %eax (32-bit accumulator, standard for return values in System V ABI)
/// - Immediate: $value (compile-time constants for direct instruction encoding)
/// - Standard AT&T syntax ensures compatibility with gcc toolchain
///
/// Why separate Linux operand function:
/// - Maintains platform abstraction for potential future differences
/// - Enables platform-specific optimizations and register choices
/// - Clean separation of concerns between platforms
/// - Foundation for supporting different architectures (x86-64, ARM, etc.)
fn show_operand(operand: assembly.Operand) -> String {
  case operand {
    assembly.Register -> "%eax"
    assembly.Imm(i) -> "$" <> string.inspect(i)
  }
}

/// Generate platform-specific function label names for assembly output
///
/// Label naming conventions:
/// - Different platforms have different symbol naming requirements
/// - Affects linking, debugging, and symbol resolution
/// - Must match platform C calling conventions for interoperability
/// - Critical for proper function calls and symbol table generation
///
/// Platform differences:
/// - OSX: Functions prefixed with underscore (_main, _printf, _exit)
/// - Linux: Functions use bare names (main, printf, exit)
/// - Historical difference from early Unix and BSD systems
///
/// Why this matters:
/// - Incorrect naming breaks linking with C standard library
/// - Debuggers expect platform-standard symbol names
/// - System calls and library functions use platform conventions
/// - Generated code must integrate with existing object files
/// - Standard practice in all C compilers targeting these platforms
fn show_label(name: String, platform: settings.Platform) -> String {
  case platform {
    settings.OSX -> "_" <> name
    settings.Linux -> name
  }
}

/// Generate platform-specific stack security metadata for object files
///
/// Stack security annotations:
/// - Modern systems require explicit marking of stack execution requirements
/// - Prevents accidental execution of stack data (security measure)
/// - Required by some distributions and security-hardened systems
/// - Part of object file metadata, not executable code
///
/// Platform requirements:
/// - Linux: GNU stack note marks stack as non-executable (NX bit support)
/// - OSX: No explicit stack note required (handled by linker/loader)
/// - Security feature to prevent stack-based code injection attacks
///
/// GNU stack note format:
/// - .section .note.GNU-stack,"",@progbits creates special ELF section
/// - Empty section indicates stack should not be executable
/// - Linker combines notes from all object files to determine final stack permissions
/// - Standard practice in all GNU/Linux toolchains
///
/// Why security matters:
/// - Prevents return-oriented programming (ROP) attacks
/// - Enables hardware NX (No eXecute) bit enforcement
/// - Required for modern Linux distributions and security policies
/// - Standard practice in production compilers and system software
fn emit_stack_note(platform: settings.Platform) -> String {
  case platform {
    settings.OSX -> ""
    settings.Linux -> "\t.section .note.GNU-stack,\"\",@progbits\n"
  }
}
