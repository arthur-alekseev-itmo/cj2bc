package cj2bc.ast.tree

import std.collection.ArrayList
import cj2bc.ast.types.Type

public enum CjBinaryOperator {
    | Add | Sub | Mul | Div | Mod
    | Eq | Neq | Ge | Le | Gt | Lt
    | And | Or
    | BitAnd | BitOr | BitXor
}

public enum CjUnaryOperator {
    | Neg
    | Not
}

public enum CjExpr {
    | ScConstUnit
    | ScConstInt64(Int64)
    | ScConstBool(Bool)
    | ScIfThenElse(TypedExpr, TypedExpr, ?TypedExpr)
    | ScBinaryOperator(CjBinaryOperator, TypedExpr, TypedExpr)
    | ScUnaryOperator(CjUnaryOperator, TypedExpr)
    | ScCall(TypedExpr, ArrayList<TypedExpr>)
    | ScBlockExpr(TypedBlock)
    | ScReturn(TypedExpr)
    | ScAssign(TypedExpr, TypedExpr)
    | ScVarRef(String)
    | ScMemberAccess(TypedExpr, String)
}

public class TypedExpr {
    public var expr: CjExpr
    public var ty: Type

    public init(expr: CjExpr, ty: Type) {
        this.expr = expr
        this.ty = ty
    }
}
