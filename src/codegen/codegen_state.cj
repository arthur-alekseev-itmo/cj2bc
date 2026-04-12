package cj2bc.codegen

import cj2bc.bytecode.Bytecode

public class CodegenState {
    public let bytecode = Bytecode()
    public let linkerData = LinkerData()
    public var locals = LocalsContextFrame()
    
    public func pushLocalsFrame() {
        locals = LocalsContextFrame(locals)
    }

    public func popLocalsFrame() {
        locals = match (locals.getParent()) {
            case Some(p) => p
            case None => throw Exception("Popped from global frame")
        }
    }
}

