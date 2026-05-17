package cj2bc.transform

import cj2bc.simpletree.tree.*
import cj2bc.analysis.typing.types.*
import cj2bc.analysis.SymbolsScope
import std.ast.Modifier

// What it does:
// Ctor: function -> ctor
// TODO: Method overloads -> single method with dyn resolution

private type Scope = SymbolsScope

public class Transform {

    private static func transformClassDecl(c: ClassDeclData, scope: Scope): Unit {
        let newScope = scope.enterSymbol(c.name)
        c.innerDecls.map { d: TypedDecl => transformDecl(d, newScope) } 
    }

    private static func makeReturn(expr: TypedExpr) {
        TypedDecl(ScRunExpr(TypedExpr(ScReturn(expr), TNothing)), TNothing)
    }

    private static func addReturnToBlock(block: TypedBlock, _: Scope) {
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

    private static func transformFuncDecl(_: TypedDecl, f: FuncDeclData, scope: Scope): Unit {
        addReturnToBlock(f.body, scope)

        if (f.name == "init") {
            f.name = "()"
            f.functionType = FtCtor
            return
        }

        if (!scope.isRoot()) {
            f.functionType = FtMethod
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

    public static func transform(program: SimpleProgram, scope: Scope): Unit {
        program.map { d: TypedDecl => transformDecl(d, scope) }
    }
}