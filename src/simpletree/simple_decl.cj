package cj2bc.simpletree

import std.collection.ArrayList

public type SimpleBlock = ArrayList<SimpleDecl>

public class FuncDeclData {
    let parameters: ArrayList<SimplePattern>
    let body: SimpleBlock

    init(parameters: ArrayList<SimplePattern>, body: SimpleBlock) {
        this.parameters = parameters
        this.body = body
    }
}

public type SimpleProgram = ArrayList<SimpleDecl>

public enum SimpleDecl {
    | ScFuncDecl(FuncDeclData)
    | ScVarDecl(SimplePattern, SimpleExpr)
    | ScRunExpr(SimpleExpr)
}
