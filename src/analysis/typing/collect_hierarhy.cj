package cj2bc.analysis.typing

import std.collection.ArrayList
import std.collection.HashMap
import cj2bc.simpletree.tree.*
import cj2bc.analysis.typing.types.*
import cj2bc.utils.todo

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

    func findType(name: String) {
        types[name]
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

    func findType(name: String): HierarhicalType {
        match (this) {
            case InType(_, p) => p.findType(name)
            case Global(h) => h.findType(name)
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

    private func resolveSimpleType(sty: SimpleType, scope: Scope): HierarhicalType {
        match (sty) {
            case StRefType(ref) => scope.findType(ref.name)
            case _ => todo()
        }
    }

    private func isInterface(t: HierarhicalType) {
        match (t) {
            case ok: InterfaceType => true
            case _ => false
        }
    }

    private func connectClassDecl(classDecl: ClassDeclData, scope: Scope) {
        let klassOption = scope.findType(classDecl.name) as ClassType
        let klass = klassOption.getOrThrow()
        let superTypes = classDecl.superTypes.map { ty => resolveSimpleType(ty, scope) }
        let ifaces = superTypes.filterMap { i => i as InterfaceType }
        let classes = superTypes.filterMap { c => c as ClassType }
        
        ifaces.map { i: InterfaceType => klass.addImplement(i) }
        if (classes.size > 1) {
            throw Exception("More than one superclass")
        }
        classes.map { i: ClassType => klass.setExtend(i) }
        let newScope = InType(klass, scope)
        classDecl.innerDecls.map { d: SimpleDecl => connectDecl(d, newScope) }
    }

    private func connectFuncDecl(f: FuncDeclData, scope: Scope) {
        // Nothing to be done
    }

    private func connectInterfaceDecl(interfaceDecl: InterfaceDeclData, scope: Scope) {
        let iface = scope.findType(interfaceDecl.name)
        let superTypes = interfaceDecl.superTypes.map { ty => resolveSimpleType(ty, scope) }
        let ifaces = superTypes.filterMap { i => i as InterfaceType }
        if (ifaces.size != superTypes.size) {
            throw Exception("Interface implements non interface")
        }
        ifaces.map { i: InterfaceType => iface.addImplement(i) }
        let newScope = InType(iface, scope)
        interfaceDecl.innerDecls.map { d: SimpleDecl => connectDecl(d, newScope) }
    }

    private func connectDecl(decl: SimpleDecl, scope: Scope): Unit {
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