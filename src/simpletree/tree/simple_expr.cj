package cj2bc.simpletree.tree

import std.collection.ArrayList
import std.ast.Pattern

public enum SimpleBinaryOperator {
    | Add | Sub | Mul | Div | Mod
    | Eq | Neq | Ge | Le | Gt | Lt
    | And | Or
    | BitAnd | BitOr | BitXor
}

public enum SimpleUnaryOperator {
    | Neg
    | Not
}

public enum SimpleExpr {
    | ScConstUnit
    | ScConstInt64(Int64)
    | ScConstBool(Bool)
    | ScIfThenElse(SimpleExpr, SimpleExpr, ?SimpleExpr)
    | ScBinaryOperator(SimpleBinaryOperator, SimpleExpr, SimpleExpr)
    | ScUnaryOperator(SimpleUnaryOperator, SimpleExpr)
    | ScCall(SimpleExpr, ArrayList<SimpleExpr>)
    | ScBlockExpr(SimpleBlock)
    | ScReturn(SimpleExpr)
    | ScAssign(SimpleExpr, SimpleExpr)
    | ScVarRef(String)
}
