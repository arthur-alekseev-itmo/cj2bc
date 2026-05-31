package cj2bc.parse

import cj2bc.ast.tree.*
import std.ast.*
import cj2bc.utils.todo
import std.collection.ArrayList


public class CjParser {
    public static func parse(input: String): CjProgram {
        let tokens = cangjieLex(input)
        let program = parseProgram(tokens)
        return program.decls.map { decl: Decl =>
            CjDeclParser.translateDecl(decl)
        }
    }

    public static func translateNode(node: Node): TypedDecl {
        match (node) {
            case expr: Expr => TypedDecl(ScRunExpr(CjExprParser.translateExpr(expr)), TUnknown)
            case decl: Decl => CjDeclParser.translateDecl(decl)
            case _ => todo()
        }
    }

    public static func translateBlock(block: Block): TypedBlock {
        block.nodes.map(translateNode)
    }
}
