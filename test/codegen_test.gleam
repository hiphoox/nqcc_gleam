import assembly
import ast
import codegen
import gleam/list
import gleeunit/should

pub fn generate_simple_function_test() {
  let program =
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(42))))

  codegen.generate(program)
  |> should.equal(
    assembly.Program(
      assembly.Function(name: "main", instructions: [
        assembly.Mov(assembly.Imm(42), assembly.Register),
        assembly.Ret,
      ]),
    ),
  )
}

pub fn generate_function_with_zero_return_test() {
  let program =
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(0))))

  codegen.generate(program)
  |> should.equal(
    assembly.Program(
      assembly.Function(name: "main", instructions: [
        assembly.Mov(assembly.Imm(0), assembly.Register),
        assembly.Ret,
      ]),
    ),
  )
}

pub fn generate_function_with_different_name_test() {
  let program =
    ast.Program(ast.Function(name: "foo", body: ast.Return(ast.Constant(100))))

  codegen.generate(program)
  |> should.equal(
    assembly.Program(
      assembly.Function(name: "foo", instructions: [
        assembly.Mov(assembly.Imm(100), assembly.Register),
        assembly.Ret,
      ]),
    ),
  )
}

pub fn generate_function_with_large_number_test() {
  let program =
    ast.Program(ast.Function(name: "test", body: ast.Return(ast.Constant(999))))

  codegen.generate(program)
  |> should.equal(
    assembly.Program(
      assembly.Function(name: "test", instructions: [
        assembly.Mov(assembly.Imm(999), assembly.Register),
        assembly.Ret,
      ]),
    ),
  )
}

pub fn generate_function_with_negative_number_test() {
  let program =
    ast.Program(ast.Function(
      name: "negative",
      body: ast.Return(ast.Constant(-1)),
    ))

  codegen.generate(program)
  |> should.equal(
    assembly.Program(
      assembly.Function(name: "negative", instructions: [
        assembly.Mov(assembly.Imm(-1), assembly.Register),
        assembly.Ret,
      ]),
    ),
  )
}

pub fn generate_preserves_function_name_test() {
  let program =
    ast.Program(ast.Function(
      name: "my_function_name",
      body: ast.Return(ast.Constant(1)),
    ))

  let result = codegen.generate(program)
  case result {
    assembly.Program(assembly.Function(name: function_name, instructions: _)) ->
      function_name |> should.equal("my_function_name")
  }
}

pub fn generate_creates_correct_instruction_count_test() {
  let program =
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(42))))

  let result = codegen.generate(program)
  case result {
    assembly.Program(assembly.Function(name: _, instructions: instructions)) -> {
      let length = instructions |> list.length()
      length |> should.equal(2)
    }
  }
}

pub fn generate_first_instruction_is_mov_test() {
  let program =
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(42))))

  let result = codegen.generate(program)
  case result {
    assembly.Program(assembly.Function(name: _, instructions: [first, _])) ->
      case first {
        assembly.Mov(_, _) -> should.be_true(True)
        _ -> should.be_true(False)
      }
    _ -> should.be_true(False)
  }
}

pub fn generate_second_instruction_is_ret_test() {
  let program =
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(42))))

  let result = codegen.generate(program)
  case result {
    assembly.Program(assembly.Function(name: _, instructions: [_, second])) ->
      case second {
        assembly.Ret -> should.be_true(True)
        _ -> should.be_true(False)
      }
    _ -> should.be_true(False)
  }
}

pub fn generate_mov_uses_immediate_operand_test() {
  let program =
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(123))))

  let result = codegen.generate(program)
  case result {
    assembly.Program(assembly.Function(name: _, instructions: [first, _])) ->
      case first {
        assembly.Mov(assembly.Imm(value), assembly.Register) ->
          value |> should.equal(123)
        _ -> should.be_true(False)
      }
    _ -> should.be_true(False)
  }
}

pub fn generate_mov_targets_register_test() {
  let program =
    ast.Program(ast.Function(name: "main", body: ast.Return(ast.Constant(42))))

  let result = codegen.generate(program)
  case result {
    assembly.Program(assembly.Function(name: _, instructions: [first, _])) ->
      case first {
        assembly.Mov(assembly.Imm(_), assembly.Register) -> should.be_true(True)
        _ -> should.be_true(False)
      }
    _ -> should.be_true(False)
  }
}
