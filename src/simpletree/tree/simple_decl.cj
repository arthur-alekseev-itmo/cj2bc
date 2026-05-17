package cj2bc.simpletree.tree

import cj2bc.analysis.typing.types.Type
import std.collection.ArrayList
import std.ast.Modifier
import std.deriving.Derive

public type TypedBlock = ArrayList<TypedDecl>

@Derive[Equatable]
public enum FunctionType {
    | FtFunction
    | FtMethod
    | FtCtor
}

public class FuncDeclData {
    public let parameters: ArrayList<SimplePattern>
    public let body: TypedBlock
    public var name: String
    public var resultType: Type
    public let modifiers: ArrayList<Modifier>
    public var functionType: FunctionType

    public init(name: String, parameters: ArrayList<SimplePattern>, body: TypedBlock, modifiers: ArrayList<Modifier>, resultType: Type) { 
        this.functionType = FtFunction
        this.parameters = parameters
        this.body = body
        this.name = name
        this.resultType = resultType
        this.modifiers = modifiers
    }
}

open public class InterfaceDeclData {
    public let innerDecls: ArrayList<TypedDecl>
    public let name: String
    public let superTypes: ArrayList<SimpleType>

    public init(name: String, superTypes: ArrayList<SimpleType>, innerDecls: ArrayList<TypedDecl>) {
        this.name = name
        this.innerDecls = innerDecls
        this.superTypes = superTypes
    }
}

public class ClassDeclData <: InterfaceDeclData {
    public init(name: String, superTypes: ArrayList<SimpleType>, innerDecls: ArrayList<TypedDecl>) {
        super(name, superTypes, innerDecls)
    }
}

public type SimpleProgram = ArrayList<TypedDecl>

public enum SimpleDecl {
    | ScFuncDecl(FuncDeclData)
    | ScBuiltin(String)
    | ScEmptyVarDecl(SimplePattern)
    | ScVarDecl(SimplePattern, TypedExpr)
    | ScRunExpr(TypedExpr)
    | ScClassDecl(ClassDeclData)
    | ScInterfaceDecl(InterfaceDeclData)
}

public class TypedDecl {
    public let decl: SimpleDecl
    public var ty: Type

    public init(decl: SimpleDecl, ty: Type) {
        this.decl = decl
        this.ty = ty
    }
}