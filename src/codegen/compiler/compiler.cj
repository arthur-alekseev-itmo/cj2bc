package cj2bc.codegen.compiler

import cj2bc.codegen.CodegenState
import cj2bc.simpletree.tree.*

public class Compiler {

    private func appendBuiltinsTo(state: CodegenState) {
        // println(x) {
        //   builin_print(x)
        // }
        Utils.createFunctionHere("println", state)
        state.bytecode.addInstruction(CallBuiltin(0))
        state.bytecode.addInstruction(LoadImm(0))
        state.bytecode.addInstruction(Return)
    }

    public func compileProgram(program: SimpleProgram): CodegenState {
        let state = CodegenState()
        DeclCompiler.compileProgramTo(program, state)
        appendBuiltinsTo(state)
        state
    }
}
