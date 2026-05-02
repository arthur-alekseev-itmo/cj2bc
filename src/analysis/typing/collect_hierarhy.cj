package cj2bc.analysis.typing

import std.collection.ArrayList
import std.collection.HashMap
import cj2bc.simpletree.tree.*
import cj2bc.analysis.typing.types.*

class ClassHierarhy {
    let types: HashMap<String, HierarhicalType>
    let functions: HashMap<String, FunctionInfo>

    public init() {
        this.types = HashMap()
        this.functions = HashMap()
    }

    func addType(name: String, ty: HierarhicalType) {
        types.add(name, ty)
    }

    func addFunction(name: String, f: FunctionInfo) {
        functions.add(name, f)
    }
}

private enum Scope {
    | Global(ClassHierarhy)
    | InType(HierarhicalType, Scope)

    func addType(name: String, ty: HierarhicalType): Unit {
        match (this) {
            case InType(_, p) => p.addType(name, ty)
            case Global(h) => h.addType(name, ty)
        }
    }

    private static func functionToMethod(function: FuncDeclData) {
        MethodInfo(function.name, TUnknown, function.modifiers)
    }

    private static func functionToFunction(function: FuncDeclData) {
        FunctionInfo(function.name, TUnknown)
    }

    func addFunction(f: FuncDeclData): Unit {
        match (this) {
            case InType(c, _) => c.addMethod(functionToMethod(f))
            case Global(h) => h.addFunction(f.name, functionToFunction(f))
        }
    }
}

class HierarhyCollect {
    public func collectHierarhy(program: SimpleProgram): ClassHierarhy {
        let hierarhy = ClassHierarhy()
        let scope = Global(hierarhy)
        collectTypes(program, scope)
        connectTypes(program, scope)
        hierarhy
    }

    private func registerClassDecl(c: ClassDeclData, scope: Scope): Unit {
        let ty = ClassType(c.name)
        let newScope = InType(ty, scope)
        scope.addType(c.name, ty)
        c.innerDecls.map { decl: SimpleDecl => registerDecl(decl, newScope) }
    }

    private func registerFuncDecl(f: FuncDeclData, scope: Scope) {
        scope.addFunction(f)
        f.body.map { decl: SimpleDecl => registerDecl(decl, scope) }
    }

    private func registerInterfaceDecl(i: InterfaceDeclData, scope: Scope) {
        let ty = InterfaceType(i.name)
        let newScope = InType(ty, scope)
        scope.addType(i.name, ty)
        i.innerDecls.map { decl: SimpleDecl => registerDecl(decl, newScope) }
    }

    private func registerDecl(decl: SimpleDecl, scope: Scope): Unit {
        match (decl) {
            case ScFuncDecl(f, _) => registerFuncDecl(f, scope)
            case ScVarDecl(v, b, _) => () 
            case ScClassDecl(c) => registerClassDecl(c, scope)
            case ScInterfaceDecl(i) => registerInterfaceDecl(i, scope)
            case ScRunExpr(_) => ()
        }
    }

    private func collectTypes(program: SimpleProgram, scope: Scope) {
        program.map { decl: SimpleDecl => registerDecl(decl, scope) } 
    }

    private func connectClassDecl() {
        
    }

    private func connectDecl(decl: SimpleDecl, scope: Scope) {
        match (decl) {
            case ScFuncDecl(f, _) => connectFuncDecl(f, scope)
            case ScVarDecl(v, b, _) => () 
            case ScClassDecl(c) => connectClassDecl(c, scope)
            case ScInterfaceDecl(i) => connectInterfaceDecl(i, scope)
            case ScRunExpr(_) => ()
        }
   
    }

    private func connectTypes(program: SimpleProgram, scope: Scope) {
        program.map { decl: SimpleDecl => connectDecl(decl, scope) }
    }
}