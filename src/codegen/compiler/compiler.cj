package cj2bc.codegen.compiler

import cj2bc.codegen.state.CodegenState
import cj2bc.ast.tree.*
import cj2bc.common.SymbolsScope

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

    public func compileProgram(program: CjProgram, scope: SymbolsScope): CodegenState {
        let state = CodegenState(scope)
        DeclCompiler.compileProgramTo(program, state)
        appendBuiltinsTo(state)
        state
    }
}
