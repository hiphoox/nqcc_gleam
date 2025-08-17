import gleam/list
import gleam/regexp
import gleam/string
import tokens.{type Token, type TokenDef, token_defs}

/// Error type for lexical analysis failures
/// Wraps a descriptive string message about what went wrong during tokenization
pub type LexError {
  LexError(String)
}

/// Represents a successful pattern match during tokenization
/// Contains both the matched text and the token definition that matched it
/// This intermediate representation allows us to compare match lengths before
/// converting to actual tokens (implementing longest-match disambiguation)
pub type MatchDef {
  MatchDef(matched_substring: String, matching_token: TokenDef)
}

/// Main entry point for lexical analysis
/// Follows the OCaml lexer structure: initialize token definitions, then recursively lex
///
/// Why this design:
/// - Separates token definition initialization from the core lexing algorithm
/// - Handles the case where regex compilation fails (defensive programming)
/// - Converts internal error strings to proper LexError types for the public API
/// - Follows functional programming principle of making errors explicit via Result types
pub fn lex(input: String) -> Result(List(Token), LexError) {
  case token_defs() {
    Ok(defs) ->
      case lex_recursive(input, defs) {
        Ok(tokens) -> Ok(tokens)
        Error(err) -> Error(LexError(err))
      }
    Error(_) -> Error(LexError("Failed to initialize token definitions"))
  }
}

/// Core recursive lexing function that mirrors the OCaml implementation exactly
///
/// Algorithm:
/// 1. Base case: empty input → return empty token list
/// 2. Skip leading whitespace (languages typically ignore whitespace)
/// 3. Find all possible token matches at current position
/// 4. Use longest-match disambiguation (standard in lexer design)
/// 5. Convert match to token and recursively lex remainder
///
/// Why this approach:
/// - Recursive structure naturally handles variable-length input
/// - Whitespace skipping prevents tokens from being split by spaces
/// - Longest-match ensures "int" is parsed as keyword, not identifier "i" + "nt"
/// - Early return on empty input avoids unnecessary processing
/// - Error propagation preserves exact failure location for debugging
fn lex_recursive(
  input: String,
  defs: List(TokenDef),
) -> Result(List(Token), String) {
  // Base case: empty string means we've successfully tokenized everything. We break out of the recursion.
  case input {
    "" -> Ok([])
    _ -> {
      case count_leading_ws(input) {
        // Whitespace found: consume it and continue lexing
        // This implements the OCaml pattern: match count_leading_ws with Some ws_count -> lex (drop ws_count input)
        Ok(ws_count) -> lex_recursive(string.drop_start(input, ws_count), defs)
        // No whitespace: attempt to match a token
        Error(_) -> {
          // Try all token patterns against current input position
          // This implements: List.filter_map (find_match input) token_defs
          let matches =
            list.filter_map(defs, fn(token_def) { find_match(input, token_def) })
          case matches {
            [] ->
              // No patterns matched: this is a lexical error
              // Show context (first 10 chars) to help with debugging
              Error("Unexpected character at: " <> string.slice(input, 0, 10))
            _ -> {
              // Multiple matches possible: use longest-match disambiguation
              // This is standard lexer behavior to handle cases like:
              // - "return" vs "r" + "eturn" (keyword vs identifier)
              // - "123" vs "1" + "23" (full number vs separate numbers)
              case find_longest_match(matches) {
                Error(_) -> Error("No valid match found")
                Ok(longest_match) -> {
                  // Extract token converter and apply it to matched text
                  let converter = longest_match.matching_token.converter
                  let matching_substring = longest_match.matched_substring
                  let next_tok = converter(matching_substring)
                  // Advance input past the consumed text
                  let remaining =
                    string.drop_start(
                      input,
                      string.length(longest_match.matched_substring),
                    )
                  // Recursively lex the rest: next_tok :: lex remaining
                  case lex_recursive(remaining, defs) {
                    Ok(rest_tokens) -> Ok([next_tok, ..rest_tokens])
                    Error(err) -> Error(err)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Attempt to match a single token definition against the input string
///
/// Implementation details:
/// - Uses regexp.scan which finds matches starting from position 0
/// - Token regexes are anchored with "^" prefix (done in token_defs)
/// - Only cares about the first match (pattern at start of input)
/// - Returns MatchDef to preserve both the matched text and the token definition
///
/// Why this design:
/// - Anchored matching ensures we only match at current position, not anywhere in string
/// - Returning MatchDef allows longest-match comparison later
/// - Error(Nil) on no match integrates cleanly with list.filter_map
/// - Separates pattern matching from token conversion (single responsibility)
fn find_match(input: String, token_def: TokenDef) -> Result(MatchDef, Nil) {
  case regexp.scan(token_def.re, input) {
    [regexp.Match(content: matched_text, submatches: _), ..] ->
      Ok(MatchDef(matched_text, token_def))
    [] -> Error(Nil)
  }
}

/// Count leading whitespace characters for automatic whitespace skipping
///
/// Whitespace handling strategy:
/// - Most programming languages treat whitespace as token separators, not tokens
/// - We skip whitespace automatically rather than creating whitespace tokens
/// - Returns character count so caller can advance input by exact amount
/// - Uses \\s+ regex to match all Unicode whitespace (spaces, tabs, newlines)
///
/// Why return Error on no whitespace:
/// - Allows clean integration with case analysis in main lexer
/// - Distinguishes "no whitespace" from "whitespace found"
/// - Enables the pattern: match whitespace with Ok(count) -> skip, Error -> try tokens
/// - Follows OCaml pattern: match count_leading_ws with Some count -> ... | None -> ...
fn count_leading_ws(input: String) -> Result(Int, Nil) {
  case regexp.from_string("^\\s+") {
    Ok(ws_regex) ->
      case regexp.scan(ws_regex, input) {
        [regexp.Match(content: ws_text, submatches: _), ..] ->
          Ok(string.length(ws_text))
        [] -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

/// Implement longest-match disambiguation for overlapping token patterns
///
/// Longest-match rule explanation:
/// - When multiple tokens can match at the same position, choose the longest
/// - Essential for handling cases like:
///   * "return" should be KWReturn, not Identifier("r") + error
///   * "123" should be Constant(123), not Constant(1) + Constant(23)
///   * ">=" should be GreaterEqual, not Greater + Equal (if we had those tokens)
///
/// Implementation approach:
/// - Uses fold to find maximum by length comparison
/// - Prefers first match in case of ties (deterministic behavior)
/// - Returns Error only for empty list (defensive programming)
///
/// Why this matters:
/// - Standard behavior expected in all lexers/tokenizers
/// - Prevents ambiguous tokenization that would confuse the parser
/// - Matches OCaml's ListUtil.max with custom comparison function
/// - Ensures greedy matching behavior (longest possible token wins)
fn find_longest_match(matches: List(MatchDef)) -> Result(MatchDef, Nil) {
  case matches {
    [] -> Error(Nil)
    [first, ..rest] -> {
      let compare_match_lengths = fn(m1: MatchDef, m2: MatchDef) -> MatchDef {
        case
          string.length(m1.matched_substring)
          >= string.length(m2.matched_substring)
        {
          True -> m1
          False -> m2
        }
      }
      Ok(list.fold(rest, first, compare_match_lengths))
    }
  }
}
