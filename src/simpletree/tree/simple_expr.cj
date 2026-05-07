package cj2bc.simpletree.tree

import std.collection.ArrayList
import cj2bc.analysis.typing.types.Type

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
    | ScIfThenElse(TypedExpr, TypedExpr, ?TypedExpr)
    | ScBinaryOperator(SimpleBinaryOperator, TypedExpr, TypedExpr)
    | ScUnaryOperator(SimpleUnaryOperator, TypedExpr)
    | ScCall(TypedExpr, ArrayList<TypedExpr>)
    | ScBlockExpr(TypedBlock)
    | ScReturn(TypedExpr)
    | ScAssign(TypedExpr, TypedExpr)
    | ScVarRef(String)
    | ScMemberAccess(TypedExpr, String)
}

public class TypedExpr {
    public let expr: SimpleExpr
    public var ty: Type

    public init(expr: SimpleExpr, ty: Type) {
        this.expr = expr
        this.ty = ty
    }
}
