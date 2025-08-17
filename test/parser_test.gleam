import ast
import gleeunit/should
import parser
import tokens

pub fn parse_empty_token_list_test() {
  parser.parse([])
  |> should.be_error()
}

pub fn parse_simple_function_test() {
  let tokens = [
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
  ]

  parser.parse(tokens)
  |> should.be_ok()
  |> should.equal(
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(42)))),
  )
}

pub fn parse_function_with_zero_return_test() {
  let tokens = [
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
  ]

  parser.parse(tokens)
  |> should.be_ok()
  |> should.equal(
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(0)))),
  )
}

pub fn parse_function_with_large_number_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("test"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(999),
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_ok()
  |> should.equal(
    ast.Program(ast.Function(name: "test", body: ast.Return(ast.Constant(999)))),
  )
}

pub fn parse_function_with_different_name_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("foo"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(1),
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_ok()
  |> should.equal(
    ast.Program(ast.Function(name: "foo", body: ast.Return(ast.Constant(1)))),
  )
}

pub fn parse_error_missing_return_type_test() {
  let tokens = [
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_missing_function_name_test() {
  let tokens = [
    tokens.KWInt,
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_missing_open_paren_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_missing_close_paren_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_missing_open_brace_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_missing_close_brace_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.Semicolon,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_missing_return_keyword_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.Constant(42),
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_missing_semicolon_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Constant(42),
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_unexpected_token_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("main"),
    tokens.OpenParen,
    tokens.KWVoid,
    tokens.CloseParen,
    tokens.OpenBrace,
    tokens.KWReturn,
    tokens.Semicolon,
    tokens.CloseBrace,
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_premature_end_test() {
  let tokens = [
    tokens.KWInt,
    tokens.Identifier("main"),
  ]

  parser.parse(tokens)
  |> should.be_error()
}

pub fn parse_error_extra_tokens_test() {
  let tokens = [
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
    tokens.Identifier("extra"),
  ]

  parser.parse(tokens)
  |> should.be_error()
}
