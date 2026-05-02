package cj2bc.simpletree.parser

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

    public static func translateNode(node: Node): SimpleDecl {
        match (node) {
            case expr: Expr => ScRunExpr(SimpleExprParser.translateExpr(expr))
            case decl: Decl => SimpleDeclParser.translateDecl(decl)
            case _ => todo()
        }
    }

    public static func translateBlock(block: Block): SimpleBlock {
        block.nodes.map(translateNode)
    }
}
