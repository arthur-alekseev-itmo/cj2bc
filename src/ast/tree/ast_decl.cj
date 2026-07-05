package cj2bc.ast.tree

import cj2bc.ast.types.*
import std.collection.ArrayList
import std.ast.Modifier
import std.deriving.Derive

public type TypedBlock = ArrayList<TypedDecl>

@Derive[Equatable]
public enum FunctionType {
    | FtFunction
    | FtMethod
    | FtStaticMethod
    | FtCtor
}

public class FuncDeclData {
    public let parameters: ArrayList<CjPattern>
    public var body: TypedBlock
    public var name: String
    public let modifiers: ArrayList<Modifier>
    public var typ: FunctionTypeData
    public var functionType: FunctionType

    public init(name: String, parameters: ArrayList<CjPattern>, body: TypedBlock, modifiers: ArrayList<Modifier>, typ: FunctionTypeData) { 
        this.functionType = FtFunction
        this.parameters = parameters
        this.body = body
        this.typ = typ
        this.name = name
        this.modifiers = modifiers
    }
}

open public class InterfaceDeclData {
    public let innerDecls: ArrayList<TypedDecl>
    public let name: String
    public let superTypes: ArrayList<CjType>
    public var ty: ?HierarhicalType = None

    public init(name: String, superTypes: ArrayList<CjType>, innerDecls: ArrayList<TypedDecl>) {
        this.name = name
        this.innerDecls = innerDecls
        this.superTypes = superTypes
    }
}

public class CjVarDecl {
    public let pattern: CjPattern
    public let value: ?TypedExpr
    public let modifiers: ArrayList<Modifier>

    public init(pattern: CjPattern, value: ?TypedExpr, modifiers: ArrayList<Modifier>) {
        this.pattern = pattern
        this.value = value
        this.modifiers = modifiers
    }
}

public class ClassDeclData <: InterfaceDeclData {
    public init(name: String, superTypes: ArrayList<CjType>, innerDecls: ArrayList<TypedDecl>) {
        super(name, superTypes, innerDecls)
    }
}

public type CjProgram = ArrayList<TypedDecl>

public enum CjDecl {
    | ScFuncDecl(FuncDeclData)
    | ScBuiltin(String)
    | ScVarDecl(CjVarDecl)
    | ScRunExpr(TypedExpr)
    | ScClassDecl(ClassDeclData)
    | ScInterfaceDecl(InterfaceDeclData)
}

public class TypedDecl {
    public var decl: CjDecl
    public var ty: Type

    public init(decl: CjDecl, ty: Type) {
        this.decl = decl
        this.ty = ty
    }
}