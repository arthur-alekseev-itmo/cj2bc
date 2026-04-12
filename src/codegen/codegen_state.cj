package cj2bc.codegen

import cj2bc.bytecode.Bytecode

public class CodegenState {
    public let bytecode = Bytecode()
    public let linkerData = LinkerData()
    public let locals = LocalsContext()
}
