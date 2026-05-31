package cj2bc.semantic.transform

import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.common.SymbolsScope
import std.collection.ArrayList

private type Scope = SymbolsScope

public class ConstructorTransforms {
    private static func changeReturnToReturnThis(decl: TypedDecl) {
        if (let ScRunExpr(e) <- decl.decl) {
            if (let ScReturn(e) <- e.expr) {
                e.expr = ScReturn(TypedExpr(ScVarRef("this"), TUnknown))
            }
        }
    }

    public static func addExplicitReturnThisToCtor(f: FuncDeclData): Unit {
        // TODO: Go into exprs to ensure if blocks
        f.body.map(changeReturnToReturnThis)
        // TODO: Remove duplicate if detected
        let returnThis = TypedDecl(ScRunExpr(TypedExpr(ScReturn(TypedExpr(ScVarRef("this"), TUnknown)), TNothing)), TNothing)
        f.body.add(returnThis)
    }

    private static func patternToThisExpr(pat: CjPattern) {
        match (pat) {
            case ScVariable(v, _) => ScMemberAccess(TypedExpr(ScVarRef("this"), TUnknown), v)
        }
    }

    public static func addFieldInitialisationToCtor(f: FuncDeclData, scope: Scope): Unit {
        func tryGetField(decl: TypedDecl) {
            match (decl.decl) {
                case ScVarDecl(f, expr) => Some((f, expr))
                case _ => None<(CjPattern, TypedExpr)>
            }
        }
        let initializableFields = scope.getSymbols().values().iterator().filterMap(tryGetField)
        let initializationBlock = ArrayList<TypedDecl>()
        for ((declaration, expr) in initializableFields) {
            let pat = TypedExpr(patternToThisExpr(declaration), TUnknown)
            let initInstruction = TypedDecl(ScRunExpr(TypedExpr(ScAssign(pat, expr), TBasic(TUnit))), TBasic(TUnit))
            initializationBlock.add(initInstruction)
        }
        f.body.add(all: initializationBlock, at: 0)
    }
}