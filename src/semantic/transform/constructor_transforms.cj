package cj2bc.semantic.transform

import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.common.SymbolsScope
import cj2bc.common.ScopeOrigin
import std.collection.ArrayList

import std.ast.Modifier
import std.ast.TokenKind

private type Scope = SymbolsScope

public class ConstructorTransforms {
    private static func patternToThisExpr(pat: CjPattern) {
        match (pat) {
            case ScVariable(v, _) => ScMemberAccess(TypedExpr(ScVarRef("this"), TUnknown), v)
        }
    }

    public static func addFieldInitialisationToCtor(f: FuncDeclData, scope: Scope, takeStatics!: Bool = false): Unit {
        func tryGetField(decl: TypedDecl) {
            match (decl.decl) {
                case ScVarDecl(v) where v.value.isSome() =>
                    let isStatic = v.modifiers.any { m: Modifier => m.keyword.kind == TokenKind.STATIC }
                    if (takeStatics == isStatic) {
                        Some((v.pattern, v.value.getOrThrow()))
                    } else {
                        None<(CjPattern, TypedExpr)>
                    }
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
        let emptyCtorTyp = TFunction(ArrayList<Type>(), TUnknown)
        let declData = FuncDeclData("init", ArrayList(), ArrayList(), ArrayList(), TUnknown)
        let emptyCtor = TypedDecl(ScFuncDecl(declData), emptyCtorTyp)
        scope.createSymbol("init", ScopeOrigin.FunctonScope(declData))
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

    private static func fixSuperCallInDecl(decl: TypedDecl, _: Scope): Unit {
        if (let ScRunExpr(scCall) <- decl.decl) {
            if (let ScCall(superVar, args) <- scCall.expr) {
                if (let ScVarRef(x) <- superVar.expr) {
                    let initMethodExpr = TypedExpr(ScMemberAccess(superVar, "init"), TUnknown)
                    let initCall = ScRunExpr(TypedExpr(ScCall(initMethodExpr, args), TUnknown))
                    decl.decl = initCall
                } 
            }
        }
    }

    // Fix: super(...Args) -> super.init(...Args)
    public static func fixSuperCallInCtor(ctor: FuncDeclData, scope: Scope): Unit {
        let fDecl = { x: TypedDecl => fixSuperCallInDecl(x, scope) }
        func fExpr(e: TypedExpr): Unit {
            AstUtils.iterExpr(e, fExpr, fDecl)
        }
        ctor.body.map { decl: TypedDecl =>
            fDecl(decl)
            AstUtils.iterDecl(decl, fExpr, fDecl)
        }
    }

    public static func addClinit(klass: ClassDeclData, scope: Scope): Unit {
        let clinitType = TFunction(ArrayList<Type>(), TUnknown)
        let clinitDeclData = FuncDeclData("$clinit", ArrayList(), ArrayList(), ArrayList(), TUnknown)
        let clinit = TypedDecl(ScFuncDecl(clinitDeclData), clinitType)
        clinitDeclData.functionType = FtStaticMethod
        scope.createSymbol("$clinit", ScopeOrigin.FunctonScope(clinitDeclData))
        addFieldInitialisationToCtor(clinitDeclData, scope, takeStatics: true)
        let returnUnit = TypedDecl(ScRunExpr(TypedExpr(ScReturn(TypedExpr(ScConstUnit, TBasic(TUnit))), TNothing)), TNothing)
        clinitDeclData.body.add(returnUnit)
        klass.innerDecls.add(clinit)
    }
}