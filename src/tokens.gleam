import gleam/int
import gleam/regexp
import gleam/result

/// Token representation - atomic lexical units of the C language subset
///
/// Token design philosophy:
/// - Represents smallest meaningful units recognized by the lexer
/// - Bridges raw source text and structured syntax analysis
/// - Each token type corresponds to specific language constructs
/// - Foundation for syntax analysis and grammar rule matching
///
/// Token categories and purposes:
///
/// **Identifiers and Literals:**
/// - Identifier(String): User-defined names (variables, functions)
///   * Contains actual identifier text from source code
///   * Used for function names, variable names, type names
///   * Must follow C identifier rules: [A-Za-z_][A-Za-z0-9_]*
///   * Case-sensitive and preserves exact source spelling
/// - Constant(Int): Integer literal values (42, 100, -5)
///   * Contains parsed integer value for immediate use
///   * Represents compile-time known numeric constants
///   * Foundation for arithmetic expressions and return values
///   * Currently supports decimal integers only
///
/// **Keywords (Reserved Words):**
/// - KWInt: "int" keyword for integer type declarations
///   * Function return type specifier in current grammar
///   * Foundation for variable declarations in future extensions
///   * Reserved word that cannot be used as identifier
/// - KWReturn: "return" keyword for function return statements
///   * Terminates function execution with optional value
///   * Required in non-void functions in C semantics
///   * Maps to return statement in AST
/// - KWVoid: "void" keyword for empty parameter lists
///   * Indicates function takes no parameters: func(void)
///   * Foundation for void return types in future extensions
///   * C language requirement for parameterless functions
///
/// **Punctuation and Delimiters:**
/// - OpenParen/CloseParen: "(" and ")" for grouping and function calls
///   * Function parameter lists: func(void)
///   * Expression grouping for precedence: (a + b) * c
///   * Future: function calls, conditional expressions
/// - OpenBrace/CloseBrace: "{" and "}" for block statements
///   * Function body delimiters: { statements }
///   * Future: compound statements, scope boundaries
///   * Critical for C block structure and statement grouping
/// - Semicolon: ";" for statement termination
///   * Ends statements in C syntax: return 42;
///   * Required by C grammar for statement separation
///   * Enables statement sequence parsing
///
/// **Missing token types (future language features):**
/// - Arithmetic operators: +, -, *, /, % for expressions
/// - Comparison operators: <, >, <=, >=, ==, != for conditionals
/// - Assignment operators: =, +=, -=, etc. for variable modification
/// - Logical operators: &&, ||, ! for boolean expressions
/// - Bitwise operators: &, |, ^, <<, >> for bit manipulation
/// - Increment/decrement: ++, -- for variable updates
/// - Additional punctuation: [], ->, ., , for arrays and structs
/// - String literals: "hello" for text data
/// - Character literals: 'a' for single characters
/// - Floating-point constants: 3.14, 1e10 for real numbers
///
/// **Why this minimal token set:**
/// - Sufficient for simple C function compilation (return statements)
/// - Focuses on core lexical analysis concepts without overwhelming complexity
/// - Foundation for incremental language feature addition
/// - Demonstrates complete lexer-to-executable pipeline
/// - Educational clarity: easy to understand token-to-grammar mapping
///
/// **Token design principles:**
/// - Each token represents exactly one lexical unit
/// - Token variants use descriptive names (KWInt vs IntKeyword)
/// - Data-carrying tokens (Identifier, Constant) preserve source information
/// - Punctuation tokens are stateless (no associated data needed)
/// - Token equality enables precise syntax matching in parser
/// - Extensible design allows easy addition of new token types
///
/// **Lexical analysis integration:**
/// - Tokens are produced by lexer from character stream
/// - Regular expressions define token recognition patterns
/// - Longest-match disambiguation resolves overlapping patterns
/// - Token stream consumed sequentially by parser
/// - Error handling preserves token context for debugging
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

/// Token definition - specifies how to recognize and convert lexical patterns
///
/// TokenDef design philosophy:
/// - Encapsulates both pattern recognition and token conversion in single structure
/// - Separates lexical pattern matching from token construction logic
/// - Enables data-driven lexer configuration through declarative token definitions
/// - Foundation for extensible lexer that can easily add new token types
///
/// TokenDef components and purposes:
/// - re: regexp.Regexp - compiled regular expression for pattern matching
///   * Defines lexical pattern that identifies this token in source text
///   * Anchored to match only at current input position (^prefix ensures this)
///   * Compiled once during initialization for performance efficiency
///   * Uses standard regex syntax for maximum flexibility and power
///   * Examples: "^[A-Za-z_][A-Za-z0-9_]*" for identifiers, "^[0-9]+" for numbers
/// - converter: fn(String) -> Token - function to transform matched text into token
///   * Takes matched substring and produces appropriate Token variant
///   * Handles token-specific logic: keyword recognition, number parsing, etc.
///   * Separates pattern matching from semantic interpretation
///   * Enables reusable conversion logic across similar token types
///   * Examples: convert_identifier for names, convert_int for numbers, literal for fixed strings
///
/// TokenDef usage in lexing pipeline:
/// 1. Lexer iterates through all TokenDef entries for current input position
/// 2. Each TokenDef regex is tested against remaining input string
/// 3. Successful matches create MatchDef entries with matched text and TokenDef
/// 4. Longest-match disambiguation selects best match among alternatives
/// 5. Selected TokenDef converter transforms matched text into final Token
/// 6. Lexer advances past matched text and repeats process
///
/// Why this architecture:
/// - **Separation of Concerns**: Pattern recognition vs token construction
/// - **Extensibility**: Adding new tokens requires only new TokenDef entry
/// - **Performance**: Regex compilation happens once, not per match attempt
/// - **Maintainability**: Token patterns and logic centralized in token_defs function
/// - **Flexibility**: Same converter can handle multiple patterns (keywords + identifiers)
/// - **Standard Practice**: Matches lexer generator tools (lex, flex, ANTLR)
///
/// TokenDef creation pattern:
/// ```gleam
/// let def = fn(pattern, converter) {
///   case regexp.from_string("^" <> pattern) {
///     Ok(re) -> Ok(TokenDef(re, converter))
///     Error(_) -> Error(Nil)
///   }
/// }
/// ```
///
/// Example TokenDef usage:
/// - Identifiers: TokenDef(regex("^[A-Za-z_][A-Za-z0-9_]*"), convert_identifier)
/// - Numbers: TokenDef(regex("^[0-9]+"), convert_int)
/// - Keywords: Same as identifiers but converter checks for reserved words
/// - Punctuation: TokenDef(regex("^\\("), literal(OpenParen))
///
/// Future TokenDef extensions:
/// - Priority field for disambiguation beyond longest-match
/// - Context sensitivity for different lexical modes
/// - Multi-character operators with precedence handling
/// - String and character literal support with escape sequences
/// - Comment recognition and handling strategies
pub type TokenDef {
  TokenDef(re: regexp.Regexp, converter: fn(String) -> Token)
}

/// Creates a converter function for tokens that match fixed strings
///
/// For tokens like "{", ";" that have a fixed string representation,
/// we don't need to process the matched string - we know exactly which token it is.
/// This function creates a converter that ignores the matched string and returns the token.
///
/// Why this design:
/// - Eliminates redundant string processing for known fixed tokens
/// - Provides consistent interface with other converters (takes String, returns Token)
/// - Follows OCaml pattern: let literal tok _s = tok
/// - Enables reuse across different punctuation tokens
fn literal(token: Token) -> fn(String) -> Token {
  fn(_s) { token }
}

/// Convert matched identifier/keyword strings to appropriate tokens
///
/// Keyword recognition strategy:
/// - First check if the matched string is a reserved keyword
/// - If it matches a keyword, return the specific keyword token
/// - Otherwise, treat it as a user-defined identifier
///
/// Why keywords are handled here instead of separate patterns:
/// - Keywords and identifiers have identical lexical structure ([A-Za-z_][A-Za-z0-9_]*)
/// - Separating them would require complex regex alternation
/// - This approach is simpler and follows standard compiler design
/// - Matches OCaml pattern: "int" -> T.KWInt | "return" -> T.KWReturn | other -> T.Identifier other
fn convert_identifier(s: String) -> Token {
  case s {
    "int" -> KWInt
    "return" -> KWReturn
    "void" -> KWVoid
    other -> Identifier(other)
  }
}

/// Convert numeric string literals to integer constant tokens
///
/// Number parsing approach:
/// - Regex ensures we only get valid digit sequences ([0-9]+)
/// - Use Gleam's built-in int.parse for actual conversion
/// - Panic on parse failure since regex guarantees valid digits
///
/// Why panic on parse error:
/// - The regex [0-9]+ guarantees the string contains only digits
/// - If int.parse fails on digit-only string, it's a system error, not user error
/// - Panicking here indicates a bug in our lexer logic, not invalid input
/// - Matches OCaml pattern: T.Constant (int_of_string s) which also fails on invalid input
fn convert_int(s: String) -> Token {
  case int.parse(s) {
    Ok(i) -> Constant(i)
    Error(_) -> panic as "Invalid integer in convert_int"
  }
}

/// Define all token patterns and their converters for the C language lexer
///
/// Token definition strategy:
/// - Each token has a regex pattern and a converter function
/// - Patterns are anchored with "^" to match only at string start
/// - Order doesn't matter here since we use longest-match disambiguation
/// - All punctuation requires escaping in regex (e.g., \\( for literal "(")
///
/// Why this approach:
/// - Separates pattern definition from lexing algorithm (single responsibility)
/// - Allows easy addition of new tokens without changing lexer logic
/// - Regex compilation is done once at initialization, not per-token-match
/// - Follows OCaml structure: let token_defs = [def pattern converter; ...]
/// - Error propagation ensures any regex compilation failure is caught early
///
/// Pattern explanations:
/// - "[A-Za-z_][A-Za-z0-9_]*": Identifiers and keywords (C identifier rules)
/// - "[0-9]+": Integer literals (simple integers only, no floats/hex/etc)
/// - "\\(", "\\)", etc.: Punctuation (escaped for regex literal matching)
/// - "^" prefix: Anchored matching ensures we only match at current position
pub fn token_defs() -> Result(List(TokenDef), Nil) {
  // Smart constructor to compile regex patterns with anchoring
  // Mirrors OCaml: let def re_str converter = { re = Re.Pcre.regexp ~flags:[`ANCHORED] re_str; converter }
  let def = fn(re_str: String, converter: fn(String) -> Token) -> Result(
    TokenDef,
    Nil,
  ) {
    case regexp.from_string("^" <> re_str) {
      Ok(re) -> Ok(TokenDef(re, converter))
      Error(_) -> Error(Nil)
    }
  }

  // Define all tokens with their patterns and converters
  // Order matches OCaml version: identifiers, constants, then punctuation

  // Identifiers and keywords - must handle keyword recognition in converter
  use identifier_def <- result.try(def(
    "[A-Za-z_][A-Za-z0-9_]*",
    convert_identifier,
  ))
  // Integer constants - simple decimal numbers only
  use constant_def <- result.try(def("[0-9]+", convert_int))
  // Punctuation tokens - each requires regex escaping for literal matching
  use open_paren_def <- result.try(def("\\(", literal(OpenParen)))
  use close_paren_def <- result.try(def("\\)", literal(CloseParen)))
  use open_brace_def <- result.try(def("\\{", literal(OpenBrace)))
  use close_brace_def <- result.try(def("\\}", literal(CloseBrace)))
  use semicolon_def <- result.try(def(";", literal(Semicolon)))

  // Return compiled token definitions in a list
  // Lexer will try all patterns and use longest-match disambiguation
  Ok([
    identifier_def,
    constant_def,
    open_paren_def,
    close_paren_def,
    open_brace_def,
    close_brace_def,
    semicolon_def,
  ])
}
