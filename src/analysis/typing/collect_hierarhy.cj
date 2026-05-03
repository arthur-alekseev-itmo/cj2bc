package cj2bc.analysis.typing

import std.collection.ArrayList
import std.collection.HashMap
import cj2bc.simpletree.tree.*
import cj2bc.analysis.typing.types.*
import cj2bc.utils.todo

public struct SymbolDescription <: Equatable<SymbolDescription> & Hashable {
    // TODO: Stuff for overloading
    let qualifiedName: String

    public init(qualified: String) {
        this.qualifiedName = qualified
    }

    public init(scope: SymbolsScope, name: String) {
        this.qualifiedName = "${scope.qualifiedName}${name}"
    }

    public operator func ==(other: SymbolDescription) {
        this.qualifiedName == other.qualifiedName
    }

    public func hashCode(): Int64 {
        this.qualifiedName.hashCode()
    }
}


public class SymbolsScope {
    let exportedSymbols: HashMap<SymbolDescription, SimpleDecl>
    let symbols: HashMap<SymbolDescription, SimpleDecl>

    let exportedTypes: HashMap<String, HierarhicalType>
    let types: HashMap<String, HierarhicalType>

    let parent: ?SymbolsScope 
    let children: HashMap<String, SymbolsScope>
    let qualifiedName: String

    public init() {
        this.symbols = HashMap()
        this.exportedSymbols = HashMap()
        this.types = HashMap()
        this.exportedTypes = HashMap()
        this.parent = None
        this.children = HashMap()
        this.qualifiedName = ""
    }

    public static func fork(parent: SymbolsScope, name: String): SymbolsScope {
        let self = SymbolsScope(parent, name)
        parent.addChild(name, self)
        self 
    }

    private init(parent: SymbolsScope, name: String) {
        this.symbols = HashMap()
        this.exportedSymbols = HashMap()
        this.types = HashMap()
        this.exportedTypes = HashMap()
        this.parent = parent
        this.children = HashMap()
        this.qualifiedName = "${parent.qualifiedName}.${name}"
   }

    func addChild(name: String, child: SymbolsScope) {
        children.add(name, child)
    }

    func addType(name: String, ty: HierarhicalType): Unit {
        types.add(name, ty)
    }

    func addSymbol(name: String, declaration: SimpleDecl): Unit {
        symbols.add(SymbolDescription(this, name), declaration)
    }

    func findType(name: String): HierarhicalType {
        exportedTypes[name]
    }
}

private type Scope = SymbolsScope

public class HierarhyCollect {
    public func collectHierarhy(program: SimpleProgram): SymbolsScope {
        let scope = SymbolsScope()
        collectTypes(program, scope)
        connectTypes(program, scope)
        scope
    }

    private func registerClassDecl(c: ClassDeclData, scope: Scope): Unit {
        let ty = ClassType(c.name)
        let newScope = SymbolsScope.fork(scope, ty.name)
        scope.addType(c.name, ty)
        c.innerDecls.map { decl: SimpleDecl => registerDecl(decl, newScope) }
    }

    private func registerFuncDecl(f: FuncDeclData, scope: Scope) {
        scope.addSymbol(f.name, ScFuncDecl(f, None))
        f.body.map { decl: SimpleDecl => registerDecl(decl, scope) }
    }

    private func registerInterfaceDecl(i: InterfaceDeclData, scope: Scope) {
        let ty = InterfaceType(i.name)
        let newScope = SymbolsScope.fork(scope, ty.name)
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
        let newScope = SymbolsScope.fork(scope, klass.name)
        classDecl.innerDecls.map { d: SimpleDecl => connectDecl(d, newScope) }
    }

    private func connectFuncDecl(_: FuncDeclData, _: Scope) {
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
        let newScope = SymbolsScope.fork(scope, iface.name)
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