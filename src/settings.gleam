/// Compilation stage enumeration representing different points to stop compilation
///
/// Compilation pipeline stages:
/// - Source code → Preprocessing → Lexical Analysis → Syntax Analysis → Code Generation → Assembly → Linking
/// - Each stage produces intermediate output that can be inspected for debugging
/// - Allows incremental development and testing of compiler components
/// - Matches standard compiler interfaces (gcc -E, -S, -c flags)
///
/// Stage progression and purposes:
/// - Lex: Stop after tokenization (useful for lexer development and debugging)
/// - Parse: Stop after AST generation (useful for parser development and syntax checking)
/// - Codegen: Stop after assembly generation (useful for code generator testing)
/// - Assembly: Stop after assembly emission, before linking (useful for assembly inspection)
/// - Executable: Complete compilation to runnable binary (normal compilation mode)
///
/// Why this design:
/// - Enables debugging of each compilation phase independently
/// - Follows standard compiler architecture (multi-pass compilation)
/// - Allows testing intermediate representations without full compilation
/// - Supports development workflow: fix lexer → test parser → fix codegen
/// - Matches professional compiler behavior (gcc, clang, MSVC all support similar flags)
/// - Educational value: students can see output at each compilation stage
pub type Stage {
  Lex
  Parse
  Codegen
  Assembly
  Executable
}

/// Target platform enumeration for cross-compilation support
///
/// Platform differences handled:
/// - Calling conventions (function parameter passing, return values)
/// - Assembly syntax variations (AT&T vs Intel, different assembler directives)
/// - Object file formats (Mach-O on OSX, ELF on Linux)
/// - System call interfaces and ABI (Application Binary Interface)
/// - Linker behavior and runtime library locations
///
/// OSX (macOS) platform specifics:
/// - Uses Mach-O object file format
/// - Function names prefixed with underscore (_main vs main)
/// - Specific assembler directives (.section __TEXT,__text)
/// - Different stack alignment requirements
/// - Uses Apple's version of GCC/Clang assembler syntax
///
/// Linux platform specifics:
/// - Uses ELF (Executable and Linkable Format) object files
/// - Standard System V ABI calling conventions
/// - GNU assembler syntax and directives
/// - Different linker script requirements
/// - POSIX-compliant system interfaces
///
/// Why cross-compilation support:
/// - Enables development on one platform, deployment on another
/// - Essential for CI/CD pipelines (build on Linux, test on multiple platforms)
/// - Allows compiler testing across different target environments
/// - Matches industry standard practice (gcc, clang support cross-compilation)
/// - Educational value: demonstrates platform-specific code generation concepts
/// - Future extensibility: easy to add Windows, ARM, RISC-V targets
pub type Platform {
  OSX
  Linux
}
