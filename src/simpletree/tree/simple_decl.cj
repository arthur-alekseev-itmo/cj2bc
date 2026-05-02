package cj2bc.simpletree.tree

import cj2bc.analysis.typing.types.Type
import std.collection.ArrayList
import std.ast.Modifier

public type SimpleBlock = ArrayList<SimpleDecl>

public class FuncDeclData {
    public let parameters: ArrayList<SimplePattern>
    public let body: SimpleBlock
    public let name: String
    public let resultType: ?Type
    public let modifiers: ArrayList<Modifier>

    public init(name: String, parameters: ArrayList<SimplePattern>, body: SimpleBlock, modifiers: ArrayList<Modifier>) { 
        this.parameters = parameters
        this.body = body
        this.name = name
        this.resultType = None
        this.modifiers = modifiers
    }
}

open public class InterfaceDeclData {
    public let innerDecls: ArrayList<SimpleDecl>
    public let name: String
    public let superTypes: ArrayList<SimpleType>

    public init(name: String, superTypes: ArrayList<SimpleType>, innerDecls: ArrayList<SimpleDecl>) {
        this.name = name
        this.innerDecls = innerDecls
        this.superTypes = superTypes
    }
}

public class ClassDeclData <: InterfaceDeclData {
    public init(name: String, superTypes: ArrayList<SimpleType>, innerDecls: ArrayList<SimpleDecl>) {
        super(name, superTypes, innerDecls)
    }
}

public type SimpleProgram = ArrayList<SimpleDecl>

public enum SimpleDecl {
    | ScFuncDecl(FuncDeclData, ?Type)
    | ScVarDecl(SimplePattern, SimpleExpr, ?Type)
    | ScRunExpr(SimpleExpr)
    | ScClassDecl(ClassDeclData)
    | ScInterfaceDecl(InterfaceDeclData)
}
