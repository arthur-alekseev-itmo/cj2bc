package cj2bc.simpletree.parser

import cj2bc.utils.nextCnt
import cj2bc.simpletree.tree.*
import std.ast.*
import cj2bc.utils.todo
import std.collection.ArrayList


public class SimpleParser {
    public static func parse(input: String): SimpleProgram {
        let tokens = cangjieLex(input)
        let program = parseProgram(tokens)
        return program.decls.map { decl: Decl =>
            SimpleDeclParser.translateDecl(decl)
        }
    }

    public static func translateNode(node: Node): TypedDecl {
        match (node) {
            case expr: Expr => TypedDecl(ScRunExpr(SimpleExprParser.translateExpr(expr)), TUnknown(nextCnt()))
            case decl: Decl => SimpleDeclParser.translateDecl(decl)
            case _ => todo()
        }
    }

    public static func translateBlock(block: Block): TypedBlock {
        block.nodes.map(translateNode)
    }
}
