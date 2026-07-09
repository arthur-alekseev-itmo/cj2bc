package cj2bc.ast.tree

public class AstUtils {
    public static func iterDecl(decl: TypedDecl, fExpr: (TypedExpr) -> Unit, fDecl: (TypedDecl) -> Unit): Unit {
        match (decl.decl) {
            case ScFuncDecl(f) => f.body.map(fDecl)
            case ScBuiltin(_) => ()
            case ScVarDecl(v) => v.value.map(fExpr)
            case ScRunExpr(e) => fExpr(e)
            case ScClassDecl(c) => c.innerDecls.map(fDecl)
            case ScInterfaceDecl(i) => i.innerDecls.map(fDecl)
        }
    }

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
            case ScCast(target, _) =>
                fExpr(target)
        }
    }

    public static func mapExpr(expr: TypedExpr, fExpr: (TypedExpr) -> TypedExpr, fDecl: (TypedDecl) -> TypedDecl): TypedExpr{
        let inner = match (expr.expr) {
            case ScConstUnit => expr.expr
            case ScConstInt64(_)  => expr.expr
            case ScConstBool(_)  => expr.expr
            case ScIfThenElse(cond, thenBr, elseBr) => ScIfThenElse(fExpr(cond), fExpr(thenBr), elseBr.map(fExpr))
            case ScBinaryOperator(x, left, right) => ScBinaryOperator(x, fExpr(left), fExpr(right))
            case ScUnaryOperator(x, expr) => ScUnaryOperator(x, fExpr(expr))
            case ScCall(callee, args) => ScCall(fExpr(callee), args.map { a: TypedExpr => fExpr(a) })
            case ScBlockExpr(block) => ScBlockExpr(block.map { decl: TypedDecl => fDecl(decl) })
            case ScReturn(expr) => ScReturn(fExpr(expr))
            case ScAssign(target, value) => ScAssign(fExpr(target), fExpr(value))
            case ScVarRef(_) => expr.expr
            case ScCast(expr, ty) => ScCast(fExpr(expr), ty)
            case ScMemberAccess(target, x) => ScMemberAccess(fExpr(target), x)
        }

        TypedExpr(inner, expr.ty)
    }}