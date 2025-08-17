import ast.{
  type Expression, type FunctionDefinition, type Program, type Statement,
}
import gleam/result
import gleam/string
import tokens.{type Token}

/// Parser error types representing all possible syntax analysis failures
///
/// Error handling strategy:
/// - Explicit error types make all parsing failure modes visible
/// - Descriptive error messages help with debugging syntax issues
/// - Result type forces proper error handling at each parsing level
/// - Error propagation preserves context from deepest parsing failure
///
/// Error types:
/// - ParseError(String): Syntax errors with descriptive messages
///   * Used for unexpected tokens, malformed constructs
///   * Includes context about what was expected vs what was found
///   * Enables precise error reporting to help users fix syntax issues
/// - UnexpectedEndOfInput: Premature end of token stream
///   * Special case for incomplete programs (missing tokens)
///   * Common error: forgetting closing braces, semicolons
///   * Helps distinguish incomplete code from malformed code
///
/// Why explicit error types:
/// - Makes all failure modes visible and handleable
/// - Enables different error recovery strategies per error type
/// - Provides clear debugging information for parser development
/// - Follows functional programming principle of explicit error handling
/// - Foundation for more sophisticated error recovery and reporting
pub type ParseError {
  ParseError(String)
  UnexpectedEndOfInput
}

/// Token stream abstraction for sequential token consumption during parsing
///
/// Stream design philosophy:
/// - Immutable token stream that enables backtracking and error recovery
/// - Position tracking for precise error location reporting
/// - Functional approach: consuming tokens returns new stream state
/// - Separates tokenization concerns from parsing logic
///
/// Stream components:
/// - tokens: List(Token) - remaining tokens to be parsed
///   * Immutable list enables backtracking and lookahead
///   * Empty list indicates end of input for termination checking
///   * Linear consumption matches top-down parsing approach
/// - position: Int - current position in original token sequence
///   * Used for error reporting and debugging information
///   * Tracks progress through input for precise error locations
///   * Enables correlation between parse errors and source positions
///
/// Why stream abstraction:
/// - Encapsulates token consumption state in single data structure
/// - Enables functional parsing without mutable state
/// - Supports lookahead and backtracking for complex grammar rules
/// - Provides foundation for more sophisticated parsing techniques
/// - Makes parser state explicit and testable
///
/// Parsing workflow:
/// - take_token: consumes one token and returns new stream
/// - Multiple parsers can operate on same stream immutably
/// - Failed parsing branches don't affect original stream
/// - Successful parsing propagates updated stream through pipeline
pub type TokenStream {
  TokenStream(tokens: List(Token), position: Int)
}

/// Main parser entry point - converts token sequence to Abstract Syntax Tree
///
/// Parser design strategy:
/// - Top-down recursive descent parser for predictable control flow
/// - Single-pass parsing without backtracking for efficiency
/// - Functional approach with immutable data structures
/// - Clear error propagation through Result types
///
/// Parsing pipeline:
/// 1. Initialize token stream with position tracking
/// 2. Parse complete program structure starting from top-level grammar
/// 3. Propagate any parsing errors with context to caller
/// 4. Return complete AST for successful parsing
///
/// Why this design:
/// - Simple and predictable parsing algorithm
/// - Easy to understand and debug parser behavior
/// - Clear separation between tokenization and parsing phases
/// - Functional approach enables easy testing and composition
/// - Result type makes parsing failures explicit and handleable
///
/// Grammar structure:
/// - Program is top-level non-terminal in grammar
/// - Parser follows grammar production rules precisely
/// - Each grammar rule implemented as separate parsing function
/// - Recursive descent naturally handles nested language constructs
pub fn parse(tokens: List(Token)) -> Result(Program, ParseError) {
  let stream = TokenStream(tokens, 0)
  parse_program(stream)
}

/// Parse complete program structure - top-level grammar rule
///
/// Program grammar rule:
/// - program ::= function_definition
/// - Currently: single function programs only
/// - Future: multiple functions, global declarations
///
/// Parsing strategy:
/// - Parse single function definition as complete program
/// - Verify no extra tokens remain after function (syntax error if any)
/// - Construct Program AST node containing the function
/// - Ensure complete token consumption for clean parsing
///
/// Error handling:
/// - Propagate function definition parsing errors upward
/// - Report unexpected tokens after complete function
/// - Provide clear error messages for incomplete or malformed programs
///
/// Why single function validation:
/// - Current language subset supports only one function per file
/// - Extra tokens indicate syntax errors or unsupported features
/// - Complete token consumption ensures parser handled entire input
/// - Foundation for multi-function programs in future versions
///
/// Grammar enforcement:
/// - Strictly follows grammar production rules
/// - Rejects programs that don't match expected structure
/// - Enables clear error messages for syntax violations
/// - Provides foundation for language feature extensions
fn parse_program(stream: TokenStream) -> Result(Program, ParseError) {
  case parse_function_definition(stream) {
    Ok(#(func_def, remaining_stream)) -> {
      case remaining_stream.tokens {
        [] -> Ok(ast.Program(func_def))
        _ -> Error(ParseError("Unexpected tokens after function definition"))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Parse function definition - complete function declaration and body
///
/// Function grammar rule:
/// - function_definition ::= "int" identifier "(" "void" ")" "{" statement "}"
/// - Fixed function signature: int name(void) { ... }
/// - Single statement body for simplicity
///
/// Parsing sequence:
/// 1. Expect "int" keyword (return type)
/// 2. Parse function identifier (function name)
/// 3. Expect "(" (parameter list start)
/// 4. Expect "void" (no parameters)
/// 5. Expect ")" (parameter list end)
/// 6. Expect "{" (function body start)
/// 7. Parse single statement (function body)
/// 8. Expect "}" (function body end)
///
/// Why this grammar:
/// - Matches minimal C function syntax for educational clarity
/// - Fixed signature eliminates parameter parsing complexity
/// - Single statement body focuses on core parsing concepts
/// - Foundation for more complex function features
///
/// Error handling:
/// - Each step can fail with specific error messages
/// - Use syntax for clean error propagation through parsing steps
/// - Descriptive errors help identify exactly where parsing failed
/// - Failed parsing preserves original stream state
///
/// Future extensions:
/// - Multiple parameter types and names
/// - Complex statement blocks with local variables
/// - Function attributes and modifiers
/// - Generic and template functions
fn parse_function_definition(
  stream: TokenStream,
) -> Result(#(FunctionDefinition, TokenStream), ParseError) {
  use #(_, stream) <- result.try(expect_token(stream, tokens.KWInt))
  use #(name, stream) <- result.try(parse_identifier(stream))
  use #(_, stream) <- result.try(expect_token(stream, tokens.OpenParen))
  use #(_, stream) <- result.try(expect_token(stream, tokens.KWVoid))
  use #(_, stream) <- result.try(expect_token(stream, tokens.CloseParen))
  use #(_, stream) <- result.try(expect_token(stream, tokens.OpenBrace))
  use #(statement, stream) <- result.try(parse_statement(stream))
  use #(_, stream) <- result.try(expect_token(stream, tokens.CloseBrace))

  Ok(#(ast.Function(name, statement), stream))
}

/// Parse statement - action-performing language constructs
///
/// Statement grammar rule:
/// - statement ::= "return" expression ";"
/// - Currently: only return statements supported
/// - Future: assignments, conditionals, loops, blocks
///
/// Return statement parsing:
/// 1. Expect "return" keyword
/// 2. Parse expression for return value
/// 3. Expect ";" statement terminator
/// 4. Construct Return AST node with expression
///
/// Why return-only statements:
/// - Minimal statement set for complete function compilation
/// - Sufficient for expression-based computational functions
/// - Foundation for more complex statement types
/// - Demonstrates statement vs expression parsing distinction
///
/// Statement semantics:
/// - Statements perform actions rather than compute values
/// - Return statements terminate function execution
/// - Semicolon termination follows C syntax conventions
/// - Expression evaluation provides return value
///
/// Error handling:
/// - Missing return keyword generates clear error message
/// - Expression parsing errors propagated with context
/// - Missing semicolon reported as syntax error
/// - Use syntax ensures clean error propagation
///
/// Future statement extensions:
/// - Variable declarations and assignments
/// - Conditional statements (if-else)
/// - Loop statements (while, for)
/// - Compound statements (blocks with multiple statements)
/// - Control flow statements (break, continue)
fn parse_statement(
  stream: TokenStream,
) -> Result(#(Statement, TokenStream), ParseError) {
  use #(_, stream) <- result.try(expect_token(stream, tokens.KWReturn))
  use #(exp, stream) <- result.try(parse_expression(stream))
  use #(_, stream) <- result.try(expect_token(stream, tokens.Semicolon))

  Ok(#(ast.Return(exp), stream))
}

/// Parse expression - value-producing language constructs
///
/// Expression grammar strategy:
/// - Currently delegates to integer constant parsing
/// - Foundation for operator precedence and associativity
/// - Future: arithmetic operators, function calls, variables
///
/// Expression hierarchy (future extensions):
/// - Primary expressions: constants, identifiers, parenthesized expressions
/// - Unary expressions: negation, logical not, address-of
/// - Binary expressions: arithmetic, comparison, logical operators
/// - Assignment expressions: variable modification
/// - Function call expressions: function invocation with arguments
///
/// Why start with constants only:
/// - Simplest expression type for complete compilation pipeline
/// - No operator precedence parsing complexity
/// - Foundation for more sophisticated expression parsing
/// - Sufficient for return statement values
///
/// Future parsing approach:
/// - Recursive descent with precedence climbing
/// - Separate parsing functions for each precedence level
/// - Left-to-right associativity for same-precedence operators
/// - Proper handling of parentheses for grouping
///
/// Expression evaluation:
/// - Expressions produce values during code generation
/// - Type checking ensures expression consistency
/// - Constant folding optimizes compile-time known values
/// - Complex expressions generate instruction sequences
fn parse_expression(
  stream: TokenStream,
) -> Result(#(Expression, TokenStream), ParseError) {
  parse_integer(stream)
}

/// Parse integer constant expression - literal numeric values
///
/// Integer parsing strategy:
/// - Consume single Constant token from token stream
/// - Convert token value directly to AST Constant expression
/// - Validate token type and provide clear error messages
/// - Handle end-of-input gracefully through token stream
///
/// Token-to-AST mapping:
/// - tokens.Constant(i) → ast.Constant(i)
/// - Direct value transfer preserves numeric literals
/// - No computation or transformation required
/// - Maintains source code integer values precisely
///
/// Error handling:
/// - Wrong token type generates descriptive error message
/// - Shows expected vs actual token for debugging
/// - End-of-input errors propagated from take_token
/// - Pattern matching ensures type safety
///
/// Why this approach:
/// - Simplest expression parsing for educational clarity
/// - Foundation for more complex numeric expressions
/// - Demonstrates token-to-AST conversion pattern
/// - Sufficient for return statement constant values
///
/// Future extensions:
/// - Floating-point constants
/// - Character and string literals
/// - Boolean constants (true/false)
/// - Hexadecimal and binary integer formats
/// - Negative number handling with unary minus
fn parse_integer(
  stream: TokenStream,
) -> Result(#(Expression, TokenStream), ParseError) {
  case take_token(stream) {
    Ok(#(tokens.Constant(i), new_stream)) -> Ok(#(ast.Constant(i), new_stream))
    Ok(#(other, _)) ->
      Error(ParseError(
        "Expected a constant but found " <> string.inspect(other),
      ))
    Error(e) -> Error(e)
  }
}

/// Parse identifier token - variable and function names
///
/// Identifier parsing strategy:
/// - Consume single Identifier token from token stream
/// - Extract string name from token and return as result
/// - Validate token type with descriptive error reporting
/// - Used for function names, variable names, type names
///
/// Token-to-string mapping:
/// - tokens.Identifier(name) → name (String)
/// - Preserves exact identifier text from source code
/// - No transformation or validation of identifier contents
/// - Maintains case sensitivity and character sequence
///
/// Identifier usage contexts:
/// - Function names in function definitions
/// - Variable names in declarations and references
/// - Type names in declarations and annotations
/// - Label names for control flow (future extension)
///
/// Error handling:
/// - Wrong token type generates clear error message
/// - Shows expected identifier vs actual token found
/// - End-of-input errors propagated from underlying token consumption
/// - Type-safe pattern matching prevents runtime errors
///
/// Why separate identifier parsing:
/// - Reusable across different syntactic contexts
/// - Centralizes identifier token handling logic
/// - Enables consistent error messages for identifier expectations
/// - Foundation for identifier validation and scoping
///
/// Future identifier features:
/// - Scope resolution and name binding
/// - Reserved word checking and validation
/// - Unicode identifier support
/// - Namespace and module qualification
/// - Identifier length and character validation
fn parse_identifier(
  stream: TokenStream,
) -> Result(#(String, TokenStream), ParseError) {
  case take_token(stream) {
    Ok(#(tokens.Identifier(name), new_stream)) -> Ok(#(name, new_stream))
    Ok(#(other, _)) ->
      Error(ParseError(
        "Expected an identifier but found " <> string.inspect(other),
      ))
    Error(e) -> Error(e)
  }
}

/// Consume specific expected token from stream with validation
///
/// Token expectation strategy:
/// - Consume next token and verify it matches expected value
/// - Generate descriptive error message for mismatched tokens
/// - Used for parsing fixed syntax elements (keywords, punctuation)
/// - Central validation point for all expected token parsing
///
/// Validation process:
/// 1. Take next token from stream
/// 2. Compare actual token with expected token using equality
/// 3. Return success if tokens match exactly
/// 4. Generate detailed error message if tokens don't match
/// 5. Propagate underlying token consumption errors
///
/// Error message format:
/// - "Expected [expected_token] but found [actual_token]"
/// - Uses string.inspect for readable token representation
/// - Helps developers identify exact syntax errors
/// - Provides context for debugging parser and source code
///
/// Why explicit token expectation:
/// - Centralizes token validation logic for consistency
/// - Generates uniform error messages across parser
/// - Makes grammar expectations explicit in parser code
/// - Enables easy modification of error reporting format
///
/// Usage patterns:
/// - Parsing keywords: expect_token(stream, tokens.KWReturn)
/// - Parsing punctuation: expect_token(stream, tokens.Semicolon)
/// - Parsing operators: expect_token(stream, tokens.Plus) (future)
/// - Any fixed syntax element that must appear at specific points
///
/// Token equality:
/// - Relies on Gleam's structural equality for token comparison
/// - Works correctly for all token variants and values
/// - Keywords and punctuation have no associated data
/// - Enables precise matching of expected syntax elements
fn expect_token(
  stream: TokenStream,
  expected: Token,
) -> Result(#(Token, TokenStream), ParseError) {
  case take_token(stream) {
    Ok(#(actual, new_stream)) -> {
      case actual == expected {
        True -> Ok(#(actual, new_stream))
        False ->
          Error(ParseError(
            "Expected "
            <> string.inspect(expected)
            <> " but found "
            <> string.inspect(actual),
          ))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Consume single token from stream and advance position
///
/// Token consumption strategy:
/// - Remove first token from token list immutably
/// - Advance position counter for error reporting
/// - Return consumed token and updated stream state
/// - Handle end-of-input condition gracefully
///
/// Stream state management:
/// - Creates new TokenStream with remaining tokens
/// - Increments position counter for accurate error locations
/// - Preserves immutability for functional parsing approach
/// - Enables backtracking and lookahead parsing techniques
///
/// End-of-input handling:
/// - Empty token list generates UnexpectedEndOfInput error
/// - Distinguishes premature end from other parsing errors
/// - Helps identify incomplete source code issues
/// - Enables specific error recovery for missing tokens
///
/// Why immutable stream approach:
/// - Functional programming style with no side effects
/// - Enables parser combinators and composable parsing
/// - Safe for concurrent parsing and backtracking
/// - Clear state transitions make debugging easier
///
/// Return value structure:
/// - Tuple of (consumed_token, updated_stream)
/// - Consumed token available for immediate pattern matching
/// - Updated stream passed to subsequent parsing functions
/// - Result type makes consumption failure explicit
///
/// Usage pattern:
/// - Foundation for all other token consumption functions
/// - Used by expect_token, parse_identifier, parse_integer
/// - Enables sequential token processing through parser
/// - Central point for stream state management
fn take_token(stream: TokenStream) -> Result(#(Token, TokenStream), ParseError) {
  case stream.tokens {
    [] -> Error(UnexpectedEndOfInput)
    [head, ..tail] -> Ok(#(head, TokenStream(tail, stream.position + 1)))
  }
}
