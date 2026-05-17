package cj2bc.codegen.compiler

import cj2bc.codegen.ClassData
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
        let newState = state.enterSymbol(decl.name)
        let offset = Utils.createFunctionHere(decl.name, state)

        if (decl.functionType == FtMethod) {
            let className = state.scope.getPath()
            state.classes[className].addMethod(decl.name, offset)
        }

        if (decl.functionType == FtCtor) {
            let className = state.scope.getPath()
            state.classes[className].addCtor(decl.name, offset)            
        }

        for (parameter in decl.parameters) {
            storePatternTo(parameter, newState)
        }

        ExprCompiler.compileBlockTo(decl.body, newState)
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

    private static func compileInterfaceDeclTo(iface: InterfaceDeclData, state: CodegenState) {
        let newState = state.enterSymbol(iface.name)
        iface.innerDecls.map { d: TypedDecl => compileDeclTo(d, true, newState) }
    }

    private static func compileClassDeclTo(klass: ClassDeclData, state: CodegenState) {
        let newState = state.enterSymbol(klass.name)
        let className = klass.name // newState.scope.getPath()
        let classData = ClassData(className)
        state.classes.add(className, classData)
        klass.innerDecls.map { d: TypedDecl => compileDeclTo(d, true, newState) }
    }

    public static func compileDeclTo(decl: TypedDecl, ignoreResult: Bool, state: CodegenState): Unit {
        match (decl.decl) {
            case ScFuncDecl(data) => compileFunDeclTo(data, state)
            case ScEmptyVarDecl(_) => todo()
            case ScBuiltin(_) => todo()
            case ScVarDecl(pattern, expr) => compileVarDeclTo(pattern, expr, state)
            case ScRunExpr(expr) => compileRunExprTo(expr, ignoreResult, state)
            case ScClassDecl(klass) => compileClassDeclTo(klass, state)
            case ScInterfaceDecl(iface) => compileInterfaceDeclTo(iface, state)
        }
    }

    public static func compileProgramTo(program: SimpleProgram, state: CodegenState): Unit {
        program.map { decl: TypedDecl => compileDeclTo(decl, true, state) }
    }
}