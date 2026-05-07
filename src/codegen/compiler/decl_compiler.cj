package cj2bc.codegen.compiler

import cj2bc.simpletree.tree.*
import cj2bc.codegen.CodegenState
import cj2bc.utils.todo

public class DeclCompiler {
    private static func storePatternTo(pattern: SimplePattern, state: CodegenState) {
        match (pattern) {
            case ScVariable(name, _) =>
                let variable = state.locals.addVariable(name)
                match (variable) {
                    case GlobalVariable(x) => state.bytecode.addInstruction(StoreGlobal(x))
                    case LocalVariable(x) => state.bytecode.addInstruction(StoreLocal(x))
                    case ClosureVariable(x) => state.bytecode.addInstruction(StoreClosure(x))
                }
        }
    }

    private static func compileFunDeclTo(decl: FuncDeclData, state: CodegenState) {
        Utils.createFunctionHere(decl.name, state)
        state.pushLocalsFrame()
        for (parameter in decl.parameters) {
            storePatternTo(parameter, state)
        }
        ExprCompiler.compileBlockTo(decl.body, state)
        state.popLocalsFrame()
    }

    private static func compileVarDeclTo(pattern: SimplePattern, expr: TypedExpr, state: CodegenState) {
        ExprCompiler.compileExprTo(expr, state)
        storePatternTo(pattern, state)
    }

    private static func compileRunExprTo(expr: TypedExpr, ignoreResult: Bool, state: CodegenState) {
        ExprCompiler.compileExprTo(expr, state)
        if (ignoreResult) {
            state.bytecode.addInstruction(Drop)
        }
    }

    public static func compileDeclTo(decl: TypedDecl, ignoreResult: Bool, state: CodegenState): Unit {
        match (decl.decl) {
            case ScFuncDecl(data) => compileFunDeclTo(data, state)
            case ScVarDecl(pattern, expr) => compileVarDeclTo(pattern, expr, state)
            case ScRunExpr(expr) => compileRunExprTo(expr, ignoreResult, state)
            case _ => todo()
        }
    }

    public static func compileProgramTo(program: SimpleProgram, state: CodegenState): Unit {
       program.map { decl: TypedDecl => compileDeclTo(decl, true, state) }
    }
}