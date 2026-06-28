package cj2bc.semantic.transform

import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.common.SymbolsScope
import cj2bc.common.ScopeOrigin
import std.collection.ArrayList

public class ExprTransforms {

    public static func transformVarRef(e: TypedExpr, name: String, scope: SymbolsScope): Unit {
        if (let ScopeOrigin.ClassScope(decl) <- scope.getOrigin()) {
            if (name == "super") {
                let superTy = decl.ty
                    .flatMap { t: HierarhicalType => t as ClassType }
                    .flatMap { t: ClassType => t.getExtend() }

                let tyName = decl.ty.map { x => x.name }
                if (superTy.isNone()) {
                    println("Warning: could not find supertype for ${tyName}")
                    return
                }

                let thisExpr = TypedExpr(ScVarRef("this"), TUnknown)
                e.expr = ScCast(thisExpr, superTy.getOrThrow())
            }
        }
    }

    public static func transformExpr(e: TypedExpr, scope: SymbolsScope): Unit {
        let fExpr = { e: TypedExpr => transformExpr(e, scope) }
        let fDecl = { d: TypedDecl => Desugar.transformDecl(d, scope) }
        match (e.expr) {
            case ScVarRef(r) => transformVarRef(e, r, scope)
            case _ => AstUtils.iterExpr(e, fExpr, fDecl)
        }
    }
}