package cj2bc.codegen

import std.collection.HashMap

import cj2bc.ast.tree.CjProgram
import cj2bc.common.SymbolsScope
import cj2bc.bytecode.*

import cj2bc.codegen.state.CodegenState
import cj2bc.codegen.compiler.Compiler
import cj2bc.codegen.state.ClassData
import cj2bc.codegen.linker.Linker
import cj2bc.codegen.state.LinkerLocation

public class CodegenResult <: ToString {
    private let state: CodegenState

    public init(state: CodegenState) {
        this.state = state
    }

    public func getBytecode(): Bytecode {
        state.bytecode
    }

    public func getClasses(): HashMap<String, ClassData> {
        state.classes
    }

    public func getLocations(): HashMap<String, LinkerLocation> {
        state.linkerData.getLocations()
    }

    public override func toString(): String {
        let bcString = getBytecode().toString()
        let relocString = state.linkerData.toString()
        let classStrings = state.classes.values().toArray().map { x => x.toString() }
        let classes = String.join(classStrings.toArray(), delimiter:"\n")
        "${bcString}\n${relocString}\n${classes}"
    }

    public func toFile(): BytecodeFile {
        let classesHeader = BytecodeClassesHeader()
        state.classes.mapValues { v => classesHeader.addClass(v.toClassHeader()) }
        let bytecodeHeader = BytecodeBytecodeHeader(state.bytecode)
        BytecodeFile(classesHeader, bytecodeHeader)
    }
}

public class Codegen {
    public static func codegen(program: CjProgram, scope: SymbolsScope): CodegenResult {
        let state = Compiler().compileProgram(program, scope)
        Linker().link(state)
        CodegenResult(state)
    }
}