package cj2bc.common

import cj2bc.ast.tree.*
import cj2bc.utils.todo
import std.collection.HashMap
import std.collection.ArrayList
import cj2bc.ast.types.*
import std.deriving.Derive

public struct SymbolDescription <: Equatable<SymbolDescription> & Hashable {
    // TODO: Stuff for overloading
    let name: String
    let scope: SymbolsScope

    public init(scope: SymbolsScope, name: String) {
        this.name = name
        this.scope = scope
    }

    public operator func ==(other: SymbolDescription) {
        this.name == other.name
    }

    public func hashCode(): Int64 {
        this.name.hashCode()
    }
}

public enum ScopeOrigin {
    | ClassScope(ClassDeclData)
    | InterfaceScope(InterfaceDeclData)
    | FunctonScope(FuncDeclData)
    | GlobalScope
}

public class SymbolsScope {
    private let symbols: HashMap<SymbolDescription, TypedDecl>
    private let types: HashMap<String, HierarhicalType>

    private let parent: ?SymbolsScope 
    public let children: HashMap<String, SymbolsScope>
    private let name: String
    private let path: String
    private let origin: ScopeOrigin

    public init() {
        this.symbols = HashMap()
        this.types = HashMap()
        this.parent = None
        this.children = HashMap()
        this.name = ""
        this.path = ""
        this.origin = GlobalScope
    }

    public func enterSymbol(name: String): SymbolsScope {
        if (let Some(child) <- children.get(name)) {
            return child
        }
        throw Exception("Cannot find scope with name: ${name}")
    }   

    public func createSymbol(name: String, origin: ScopeOrigin): SymbolsScope {
        let child = SymbolsScope(this, name, origin)
        addChild(name, child)
        child 
    }

    private init(parent: SymbolsScope, name: String, origin: ScopeOrigin) {
        this.symbols = HashMap()
        this.types = HashMap()
        this.parent = parent
        this.children = HashMap()
        this.name = name
        this.path = "${parent.path}.${name}"
        this.origin = origin
    }

    private func getRoot(): SymbolsScope {
        match (parent) {
            case None => this
            case Some(p) => p.getRoot()
        }
    }

    public func addChild(name: String, child: SymbolsScope): Unit {
        children.add(name, child)
    }

    public func addType(name: String, ty: HierarhicalType): Unit {
        // Anything is assumed as public at first, so added in root too
        types.add(name, ty)
        getRoot().types.add(name, ty)
    }

    public func addSymbol(name: String, declaration: TypedDecl): Unit {
        // Symbols require scope
        let description = SymbolDescription(this, name)
        symbols.add(description, declaration)
        getRoot().symbols.add(description, declaration)
    }

    public func findType(name: String): HierarhicalType {
        match ((types.get(name), parent)) {
            case (None, Some(p)) => p.findType(name)
            case (Some(x), _) => x
            case (None, None) => throw Exception("Hierarihical type was not found: ${name}")
        }
    }

    public func findSymbol(name: String): TypedDecl {
        let description = SymbolDescription(this, name)
        findSymbol(description)
    }

    public func findSymbol(description: SymbolDescription): TypedDecl {
        match ((symbols.get(description), parent)) {
            case (None, Some(p)) => p.findSymbol(description)
            case (Some(x), _) => x
            case (None, None) => throw Exception("Sybmol was not found: ${description.name}")
        }
    }

    public func getName(): String {
        name
    }
    
    public func getPath(): String {
        path
    }

    public func isRoot(): Bool {
        parent.isNone()
    }

    public func getParent(): SymbolsScope {
        parent.getOrThrow()
    }

    public func getSymbols(): HashMap<SymbolDescription, TypedDecl> {
        return this.symbols
    }
    public func getOrigin(): ScopeOrigin {
        return origin
    }
}
