import gleeunit/should
import lexer
import tokens

pub fn lex_empty_input_test() {
  lexer.lex("")
  |> should.be_ok()
  |> should.equal([])
}

pub fn lex_simple_return_statement_test() {
  lexer.lex("return 42;")
  |> should.be_ok()
  |> should.equal([
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
  ])
}

pub fn lex_function_definition_test() {
  lexer.lex("int main(void) { return 0; }")
  |> should.be_ok()
  |> should.equal([
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(0),
    tokens.Semicolon,
    tokens.CloseBrace,
  ])
}

pub fn lex_with_whitespace_test() {
  lexer.lex("  int   main  ( void )  {  return  42  ;  }  ")
  |> should.be_ok()
  |> should.equal([
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
    tokens.CloseBrace,
  ])
}

pub fn lex_identifiers_test() {
  lexer.lex("foo bar_baz test123")
  |> should.be_ok()
  |> should.equal([
    tokens.Identifier("foo"),
    tokens.Identifier("bar_baz"),
    tokens.Identifier("test123"),
  ])
}

pub fn lex_integer_literals_test() {
  lexer.lex("0 42 123")
  |> should.be_ok()
  |> should.equal([
    tokens.Constant(0),
    tokens.Constant(42),
    tokens.Constant(123),
  ])
}

pub fn lex_keywords_test() {
  lexer.lex("int return void")
  |> should.be_ok()
  |> should.equal([
    tokens.KWInt,
    tokens.KWReturn,
    tokens.KWVoid,
  ])
}

pub fn lex_punctuation_test() {
  lexer.lex("(){};")
  |> should.be_ok()
  |> should.equal([
    tokens.OpenParen,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.CloseBrace,
    tokens.Semicolon,
  ])
}

pub fn lex_mixed_tokens_test() {
  lexer.lex("int foo(int x) { return x; }")
  |> should.be_ok()
  |> should.equal([
    tokens.KWInt,
    tokens.Identifier("foo"),
    tokens.OpenParen,
    tokens.KWInt,
    tokens.Identifier("x"),
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Identifier("x"),
    tokens.Semicolon,
    tokens.CloseBrace,
  ])
}

pub fn lex_newlines_and_tabs_test() {
  lexer.lex("int\n\tmain(void)\n{\n\treturn\t42;\n}")
  |> should.be_ok()
  |> should.equal([
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
    tokens.CloseBrace,
  ])
}

pub fn lex_arithmetic_expressions_test() {
  lexer.lex("int x; return 123;")
  |> should.be_ok()
  |> should.equal([
    tokens.KWInt,
    tokens.Identifier("x"),
    tokens.Semicolon,
    tokens.KWReturn,
    tokens.Constant(123),
    tokens.Semicolon,
  ])
}

pub fn lex_void_function_test() {
  lexer.lex("void test(void) { return; }")
  |> should.be_ok()
  |> should.equal([
    tokens.KWVoid,
    tokens.Identifier("test"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Semicolon,
    tokens.CloseBrace,
  ])
}

pub fn lex_large_numbers_test() {
  lexer.lex("return 999999;")
  |> should.be_ok()
  |> should.equal([
    tokens.KWReturn,
    tokens.Constant(999_999),
    tokens.Semicolon,
  ])
}

pub fn lex_error_invalid_character_test() {
  lexer.lex("int main() { return @; }")
  |> should.be_error()
}

pub fn lex_error_invalid_token_test() {
  lexer.lex("int main() { return $invalid; }")
  |> should.be_error()
}
