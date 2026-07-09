package cj2bc.codegen.compiler

import std.ast.Modifier
import std.ast.TokenKind

import cj2bc.codegen.state.ClassData
import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.codegen.state.CodegenState
import cj2bc.common.ScopeOrigin
import cj2bc.utils.todo
import cj2bc.codegen.state.StringHasher
import cj2bc.bytecode.Instruction

import std.collection.HashSet

public class DeclCompiler {
    private static let compiledClasses = HashSet<String>()

    private static func storePatternTo(pattern: CjPattern, state: CodegenState) {
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
            let className = state.scope.getName() // state.scope.getPath()
            state.classes[className].addMethod(decl.name, offset)
        }
        
        if (decl.functionType == FtStaticMethod) {
            let className = state.scope.getName() // state.scope.getPath()
            state.classes[className].addStaticMethod(decl.name, offset)
        }

        if (decl.functionType == FtCtor) {
            let className = state.scope.getName() // state.scope.getPath()
            state.classes[className].addCtor(decl.name, offset)            
        }

        for (parameter in decl.parameters) {
            storePatternTo(parameter, newState)
        }

        ExprCompiler.compileBlockTo(decl.body, newState)
    }

    private static func compileVarDeclTo(decl: CjVarDecl, state: CodegenState) {
        if (let Some(value) <- decl.value) {
            if (let ClassScope(c) <- state.scope.getOrigin()) {
                let isStatic = decl.modifiers.any { x => x.keyword.kind == TokenKind.STATIC }
                let name = match (decl.pattern) {
                    case ScVariable(name, _) => name
                }
                if (isStatic) {
                    state.classes[c.name].addNextStaticField(name)
                } else {
                    state.classes[c.name].addNextField(name)
                }
            }
            ExprCompiler.compileExprTo(value, state)
            storePatternTo(decl.pattern, state)
        }
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

    private static func addStaticOperator(klass: ClassData, state: CodegenState) {
        // Add static operator() to act as real ctor
        // static operator()(InitArgs...) {
        //     let instance = new
        //     instance.init(InitArgs...)
        //     return instance
        // }
        let offset = Utils.createFunctionHere("()", state)
        let classNameHash = StringHasher.getHash(klass.getName())
        let initMethodHash = StringHasher.getHash("init")
        state.bytecode.addInstruction(Drop) // Drop init ref
        state.bytecode.addInstruction(New(classNameHash))
        state.bytecode.addInstruction(StoreLocal(0))
        state.bytecode.addInstruction(LoadLocal(0))
        state.bytecode.addInstruction(GetField(initMethodHash))
        state.bytecode.addInstruction(CallObject)
        state.bytecode.addInstruction(Drop)
        state.bytecode.addInstruction(LoadLocal(0))
        state.bytecode.addInstruction(Return)
        klass.addStaticMethod("()", offset)
    }

    private static func compileClassDeclTo(klass: ClassDeclData, state: CodegenState): Unit {
        let newState = state.enterSymbol(klass.name)
        let fullName = newState.scope.getPath()
        if (compiledClasses.contains(fullName)) {
            return
        }
        compiledClasses.add(fullName)

        let baseClass = match (newState.scope.findType(klass.name)) {
            case klass: ClassType => klass.getExtend()
            case _ => throw Exception("Error: Class did not have a class type")
        }
        baseClass.map { base: ClassType =>
            let baseDecl = state.scope.findSymbol(base.name)
            compileDeclTo(baseDecl, true, state)
        }

        let baseClassFieldCount = baseClass.map { base: ClassType =>
            let baseClassData = state.classes[base.name]
            baseClassData.getFieldCount()
        } ?? 0
 
        let className = klass.name
        let classData = ClassData(className, baseClassFieldCount)
        baseClass.map { x: ClassType => classData.setBaseName(x.name) }
        addStaticOperator(classData, state)
        state.classes.add(className, classData)
        klass.innerDecls.map { d: TypedDecl => compileDeclTo(d, true, newState) }
    }

    public static func compileDeclTo(decl: TypedDecl, ignoreResult: Bool, state: CodegenState): Unit {
        match (decl.decl) {
            case ScFuncDecl(data) => compileFunDeclTo(data, state)
            case ScBuiltin(_) => todo()
            case ScVarDecl(decl) => compileVarDeclTo(decl, state)
            case ScRunExpr(expr) => compileRunExprTo(expr, ignoreResult, state)
            case ScClassDecl(klass) => compileClassDeclTo(klass, state)
            case ScInterfaceDecl(iface) => compileInterfaceDeclTo(iface, state)
        }
    }

    public static func compileProgramTo(program: CjProgram, state: CodegenState): Unit {
        state.bytecode.addInstruction(Instruction.Init)
        program.map { decl: TypedDecl => compileDeclTo(decl, true, state) }
    }
}