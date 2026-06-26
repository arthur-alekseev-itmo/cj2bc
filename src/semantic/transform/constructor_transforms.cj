package cj2bc.semantic.transform

import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.common.SymbolsScope
import cj2bc.common.ScopeOrigin
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

    private static func isMemberCtor(member: TypedDecl): Bool {
        match(member.decl) {
            case ScFuncDecl(f) => f.functionType == FtCtor || f.name == "init"
            case _ => false
        }
    }

    public static func addImplcitCtor(klass: ClassDeclData, scope: Scope): Unit {
        let hasConstructors = klass.innerDecls.any(isMemberCtor)
        if (hasConstructors) {
            return
        }
        println(scope.getPath())
        let emptyCtorTyp = TFunction(ArrayList<Type>(), TUnknown)
        let declData = FuncDeclData("init", ArrayList(), ArrayList(), ArrayList(), TUnknown)
        let emptyCtor = TypedDecl(ScFuncDecl(declData), emptyCtorTyp)
        scope.createSymbol("()", ScopeOrigin.FunctonScope(declData))
        klass.innerDecls.add(emptyCtor)
    }

    private static func isSuperCall(decl: TypedDecl) {
        if (let ScRunExpr(e) <- decl.decl) {
            if (let ScCall(e, _) <- e.expr) {
                if (let ScVarRef(x) <- e.expr) {
                    return x == "super"
                }
            }
        }
        return false
    }

    public static func addImplicitSuperCall(ctor: FuncDeclData, klass: ClassDeclData, scope: Scope): Unit {
        let hasExplicitCall = ctor.body.first.map(isSuperCall) == Some(true)
        let hasSuperclass = match (scope.findType(klass.name)) {
            case klass: ClassType => klass.getExtend().isSome()
            case _ => false
        }
        if (hasExplicitCall || !hasSuperclass) {
            return
        }
        let explicitCall = TypedDecl(ScRunExpr(TypedExpr(ScCall(TypedExpr(ScVarRef("super"), TUnknown), ArrayList()), TUnknown)), TUnknown)
        ctor.body.add(explicitCall, at:0)
    }
}