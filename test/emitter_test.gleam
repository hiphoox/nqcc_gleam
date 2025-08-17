import assembly
import emitter
import gleam/string
import gleeunit/should
import settings
import simplifile

pub fn emit_simple_assembly_test() {
  let asm =
    assembly.Program(
      assembly.Function(name: "main", instructions: [
        assembly.Mov(assembly.Imm(42), assembly.Register),
        assembly.Ret,
      ]),
    )

  let test_file = "test_output.s"

  // Clean up any existing test file
  let _ = simplifile.delete(test_file)

  emitter.emit(test_file, asm, settings.Linux)
  |> should.be_ok()

  // Verify file was created
  simplifile.read(test_file)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn emit_creates_file_with_content_test() {
  let asm =
    assembly.Program(
      assembly.Function(name: "main", instructions: [
        assembly.Mov(assembly.Imm(0), assembly.Register),
        assembly.Ret,
      ]),
    )

  let test_file = "test_content.s"

  // Clean up any existing test file
  let _ = simplifile.delete(test_file)

  emitter.emit(test_file, asm, settings.Linux)
  |> should.be_ok()

  // Verify file contains expected assembly content
  case simplifile.read(test_file) {
    Ok(content) -> {
      string.contains(content, "main")
      |> should.be_true()
      string.contains(content, "mov")
      |> should.be_true()
      string.contains(content, "ret")
      |> should.be_true()
    }
    Error(_) -> should.be_true(False)
  }

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn emit_different_function_names_test() {
  let asm =
    assembly.Program(
      assembly.Function(name: "foo", instructions: [
        assembly.Mov(assembly.Imm(100), assembly.Register),
        assembly.Ret,
      ]),
    )

  let test_file = "test_foo.s"

  // Clean up any existing test file
  let _ = simplifile.delete(test_file)

  emitter.emit(test_file, asm, settings.Linux)
  |> should.be_ok()

  // Verify file contains the function name
  case simplifile.read(test_file) {
    Ok(content) -> {
      string.contains(content, "foo")
      |> should.be_true()
    }
    Error(_) -> should.be_true(False)
  }

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn emit_different_immediate_values_test() {
  let asm =
    assembly.Program(
      assembly.Function(name: "test", instructions: [
        assembly.Mov(assembly.Imm(999), assembly.Register),
        assembly.Ret,
      ]),
    )

  let test_file = "test_immediate.s"

  // Clean up any existing test file
  let _ = simplifile.delete(test_file)

  emitter.emit(test_file, asm, settings.Linux)
  |> should.be_ok()

  // Verify file contains the immediate value
  case simplifile.read(test_file) {
    Ok(content) -> {
      string.contains(content, "999")
      |> should.be_true()
    }
    Error(_) -> should.be_true(False)
  }

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn emit_negative_immediate_values_test() {
  let asm =
    assembly.Program(
      assembly.Function(name: "negative", instructions: [
        assembly.Mov(assembly.Imm(-1), assembly.Register),
        assembly.Ret,
      ]),
    )

  let test_file = "test_negative.s"

  // Clean up any existing test file
  let _ = simplifile.delete(test_file)

  emitter.emit(test_file, asm, settings.Linux)
  |> should.be_ok()

  // Verify file contains the negative value
  case simplifile.read(test_file) {
    Ok(content) -> {
      string.contains(content, "-1")
      |> should.be_true()
    }
    Error(_) -> should.be_true(False)
  }

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn emit_macos_platform_test() {
  let asm =
    assembly.Program(
      assembly.Function(name: "main", instructions: [
        assembly.Mov(assembly.Imm(42), assembly.Register),
        assembly.Ret,
      ]),
    )

  let test_file = "test_macos.s"

  // Clean up any existing test file
  let _ = simplifile.delete(test_file)

  emitter.emit(test_file, asm, settings.OSX)
  |> should.be_ok()

  // Verify file was created
  simplifile.read(test_file)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn emit_creates_proper_s_extension_test() {
  let asm =
    assembly.Program(
      assembly.Function(name: "main", instructions: [
        assembly.Mov(assembly.Imm(42), assembly.Register),
        assembly.Ret,
      ]),
    )

  let test_file = "test_program.s"

  // Clean up any existing test file
  let _ = simplifile.delete(test_file)

  emitter.emit(test_file, asm, settings.Linux)
  |> should.be_ok()

  // Verify file exists with .s extension
  simplifile.read(test_file)
  |> should.be_ok()

  // Clean up
  let _ = simplifile.delete(test_file)
}

pub fn emit_overwrites_existing_file_test() {
  let asm1 =
    assembly.Program(
      assembly.Function(name: "first", instructions: [
        assembly.Mov(assembly.Imm(1), assembly.Register),
        assembly.Ret,
      ]),
    )

  let asm2 =
    assembly.Program(
      assembly.Function(name: "second", instructions: [
        assembly.Mov(assembly.Imm(2), assembly.Register),
        assembly.Ret,
      ]),
    )

  let test_file = "test_overwrite.s"

  // Clean up any existing test file
  let _ = simplifile.delete(test_file)

  // Emit first assembly
  emitter.emit(test_file, asm1, settings.Linux)
  |> should.be_ok()

  // Emit second assembly (should overwrite)
  emitter.emit(test_file, asm2, settings.Linux)
  |> should.be_ok()

  // Verify file contains second function name
  case simplifile.read(test_file) {
    Ok(content) -> {
      string.contains(content, "second")
      |> should.be_true()
      string.contains(content, "2")
      |> should.be_true()
    }
    Error(_) -> should.be_true(False)
  }

  // Clean up
  let _ = simplifile.delete(test_file)
}
