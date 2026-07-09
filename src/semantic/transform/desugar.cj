package cj2bc.semantic.transform

import std.ast.TokenKind

import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.common.SymbolsScope
import cj2bc.common.ScopeOrigin
import std.collection.ArrayList

// What it does:
// Ctor: function -> ctor
// TODO: Method overloads -> single method with dyn resolution

private type Scope = SymbolsScope

public class Desugar {

    private static func transformClassDecl(c: ClassDeclData, scope: Scope): Unit {
        let newScope = scope.enterSymbol(c.name)
        ConstructorTransforms.addClinit(c, newScope)
        ConstructorTransforms.addImplcitCtor(c, newScope)
        c.innerDecls.map { d: TypedDecl => transformDecl(d, newScope) } 
    }

    private static func makeReturn(expr: TypedExpr) {
        TypedDecl(ScRunExpr(TypedExpr(ScReturn(expr), TNothing)), TNothing)
    }

    private static func addExplicitReturnToBlock(block: TypedBlock, _: Scope) {
        let length = block.size
        if (length == 0) {
            let unit = TypedExpr(ScConstUnit, TBasic(TUnit))
            block.add(makeReturn(unit))
            return
        }
        match (block[length - 1].decl) {
            case ScRunExpr(e) => 
                match (e.expr) {
                    case ScReturn(_) => ()
                    case _ => block[length - 1] = makeReturn(e)
                }
            case _ =>
                let returnUnit = makeReturn(TypedExpr(ScConstUnit, TBasic(TUnit)))
                block.add(returnUnit)
        }
    }

    private static func addExplicitThisToMethod(f: FuncDeclData, scope: Scope) {
        f.parameters.add(ScVariable("this", None), at: 0)
        let thisDecl = ScVarDecl(CjVarDecl(ScVariable("this", None), None, ArrayList()))
        scope.enterSymbol(f.name).addSymbol("this", TypedDecl(thisDecl, TUnknown))
    }

    private static func transformFunctionInner(f: FuncDeclData, scope: Scope): Unit {
        let innerScope = scope.enterSymbol(f.name)
        for (decl in f.body) {
            transformDecl(decl, scope)
        }
    }

    private static func transformFuncDecl(_: TypedDecl, f: FuncDeclData, scope: Scope): Unit {
        if (let ScopeOrigin.ClassScope(klass) <- scope.getOrigin() && f.name == "init") {
            f.functionType = FtMethod
            ConstructorTransforms.addImplicitSuperCall(f, klass, scope)
            ConstructorTransforms.fixSuperCallInCtor(f, scope)
            addExplicitThisToMethod(f, scope)
            ConstructorTransforms.addFieldInitialisationToCtor(f, scope)
            ImplicitThisTransforms.addImplicitThisToFunc(f, klass, scope)
            transformFunctionInner(f, scope)
            addExplicitReturnToBlock(f.body, scope)
            return
        }

        addExplicitReturnToBlock(f.body, scope)

        if (let ScopeOrigin.ClassScope(klass) <- scope.getOrigin()) {
            let isStatic = f.modifiers.any { v => v.keyword.kind == TokenKind.STATIC }
            f.functionType = if (isStatic) { FtStaticMethod } else { FtMethod }
            addExplicitThisToMethod(f, scope)
            ImplicitThisTransforms.addImplicitThisToFunc(f, klass, scope)
            transformFunctionInner(f, scope)
            return
        }

        transformFunctionInner(f, scope)
    }

    public static func transformDecl(decl: TypedDecl, scope: Scope): Unit {
        match (decl.decl) {
            case ScFuncDecl(d) => transformFuncDecl(decl, d, scope)
            case ScClassDecl(c) => transformClassDecl(c, scope)
            case ScRunExpr(e) => ExprTransforms.transformExpr(e, scope)
            case _ => ()
        }
    } 

    public static func transform(program: CjProgram, scope: Scope): Unit {
        program.map { d: TypedDecl => transformDecl(d, scope) }
    }
}