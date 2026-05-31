package cj2bc.semantic.transform

import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.common.SymbolsScope
import std.collection.ArrayList

// What it does:
// Ctor: function -> ctor
// TODO: Method overloads -> single method with dyn resolution

private type Scope = SymbolsScope

public class Desugar {

    private static func transformClassDecl(c: ClassDeclData, scope: Scope): Unit {
        let newScope = scope.enterSymbol(c.name)
        c.innerDecls.map { d: TypedDecl => transformDecl(d, newScope) } 
    }

    private static func makeReturn(expr: TypedExpr) {
        TypedDecl(ScRunExpr(TypedExpr(ScReturn(expr), TNothing)), TNothing)
    }

    private static func addExplicitReturnToBlock(block: TypedBlock, _: Scope) {
        let length = block.size
        if (length == 0) {
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
        scope.enterSymbol(f.name).addSymbol("this", TypedDecl(ScEmptyVarDecl(ScVariable("this", None)), TUnknown))
    }

    private static func transformFuncDecl(_: TypedDecl, f: FuncDeclData, scope: Scope): Unit {
        if (f.name == "init") {
            f.name = "()"
            f.functionType = FtCtor
            ConstructorTransforms.addExplicitReturnThisToCtor(f)
            addExplicitThisToMethod(f, scope)
            ConstructorTransforms.addFieldInitialisationToCtor(f, scope)
            return
        }

        addExplicitReturnToBlock(f.body, scope)

        if (!scope.isRoot()) {
            f.functionType = FtMethod
            addExplicitThisToMethod(f, scope)
            return
        }
    }

    public static func transformDecl(decl: TypedDecl, scope: Scope): Unit {
        match (decl.decl) {
            case ScFuncDecl(d) => transformFuncDecl(decl, d, scope)
            case ScClassDecl(c) => transformClassDecl(c, scope)
            case ScRunExpr(e) => ()
            case _ => ()
        }
    } 

    public static func transform(program: CjProgram, scope: Scope): Unit {
        program.map { d: TypedDecl => transformDecl(d, scope) }
    }
}