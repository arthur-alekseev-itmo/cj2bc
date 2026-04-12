package cj2bc.simpletree

import std.collection.ArrayList

public type SimpleBlock = ArrayList<SimpleDecl>

public class FuncDeclData {
    public let parameters: ArrayList<SimplePattern>
    public let body: SimpleBlock
    public let name: String

    init(name: String, parameters: ArrayList<SimplePattern>, body: SimpleBlock) {
        this.parameters = parameters
        this.body = body
        this.name = name
    }
}

public type SimpleProgram = ArrayList<SimpleDecl>

public enum SimpleDecl {
    | ScFuncDecl(FuncDeclData)
    | ScVarDecl(SimplePattern, SimpleExpr)
    | ScRunExpr(SimpleExpr)
}
