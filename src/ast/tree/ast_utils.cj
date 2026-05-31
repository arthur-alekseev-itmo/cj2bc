package cj2bc.ast.tree

public class AstUtils {
    public static func iterExpr(expr: TypedExpr, fExpr: (TypedExpr) -> Unit, fDecl: (TypedDecl) -> Unit): Unit {
        match (expr.expr) {
            case ScConstUnit => ()
            case ScConstInt64(_)  => ()
            case ScConstBool(_)  => ()
            case ScIfThenElse(cond, thenBr, elseBr) =>
                fExpr(cond)
                fExpr(thenBr)
                elseBr.map(fExpr)
            case ScBinaryOperator(_, left, right) =>
                fExpr(left)
                fExpr(right)
            case ScUnaryOperator(_, expr) =>
                fExpr(expr)
            case ScCall(callee, args) =>
                fExpr(callee)
                args.map { a: TypedExpr => fExpr(a) }
            case ScBlockExpr(block) =>
                block.map { decl: TypedDecl => fDecl(decl) }
            case ScReturn(expr) =>
                fExpr(expr)
            case ScAssign(target, value) =>
                fExpr(target)
                fExpr(value)
            case ScVarRef(_) => ()
            case ScMemberAccess(target, _) =>
                fExpr(target)
        }
    }
}