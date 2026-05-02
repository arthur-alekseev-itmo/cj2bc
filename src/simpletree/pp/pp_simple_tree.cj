package cj2bc.simpletree.pp

import cj2bc.simpletree.tree.*
import cj2bc.utils.todo
import cj2bc.analysis.typing.types.*

class PpSimpleTree {
    static let LEAP = "   "

    public static func programToString(program: SimpleProgram): String {
        let declStrings = program.map { d => declToString(d, "") }
        String.join(declStrings.toArray(), delimiter:"\n")
    }

    private static func binopToString(op: SimpleBinaryOperator) {
        // TODO:
        "??"
    }

    private static func unopToString(op: SimpleUnaryOperator) {
        // TODO:
        "?"
    }

    private static func blockToString(block: SimpleBlock, offset: String) {
        let decls = block.map { d => declToString(d, offset + LEAP) }
        let strings = String.join(decls.toArray(), delimiter:"\n")
        "{\n${strings}}\n"
    }

    private static func exprToString(expr: SimpleExpr, offset: String): String {
        match (expr) {
            case ScConstUnit => "()"
            case ScConstInt64(i) => i.toString()
            case ScConstBool(b) => b.toString()
            case ScBinaryOperator(o, l, r) =>
                let left = exprToString(l, offset)
                let right = exprToString(r, offset)
                let op = binopToString(o)
                "${left} ${op} ${right}"
            case ScUnaryOperator(o, e) =>
                let expr = exprToString(e, offset)
                let op = unopToString(o)
                "${op}${expr}"
            case ScIfThenElse(c, t, e) =>
                let cond = exprToString(c, offset)
                let thenBr = exprToString(t, offset)
                let elseBr = match (e) {
                    case None => ""
                    case Some(x) => "else ${exprToString(x, offset)}"
                }
                "if (${cond}) then ${thenBr} ${elseBr}"
            case ScCall(c, a) =>
                let callee = exprToString(c, offset)
                let args = a.map { x => exprToString(x, offset) }
                "${callee}(${String.join(args.toArray(), delimiter:", ")})"
            case ScBlockExpr(b) =>
                blockToString(b, offset)
            case ScVarRef(name) =>
                name
            case ScReturn(e) =>
                let expr = exprToString(e, offset)
                "return ${expr}"
            case ScAssign(t, v) =>
                let target = exprToString(t, offset)
                let value = exprToString(v, offset)
                "${target} = ${value}" 
        }
    }

    private static func simpleTypeToString(t: SimpleType) {
        // TODO:
        return "Ty?"
    }

    private static func typeToString(t: Type) {
        return "TY?"
    }

    private static func patternToString(pattern: SimplePattern, _: String) {
        match (pattern) {
            case ScVariable(name, a, t) =>
                let annotation = a.map(simpleTypeToString).map { x => ": ${x}"}.getOrDefault {""}
                let typ = t.map(typeToString).map { x => "[${x}] "}.getOrDefault {""}
                "${typ}${name}${annotation}"
        }
    }

    private static func declToString(decl: SimpleDecl, offset: String): String {
        match (decl) {
            case ScVarDecl(v, e, t) => 
                let pattern = patternToString(v, offset)
                let expr = exprToString(e, offset)
                let ty = t.map(typeToString).getOrDefault { "" }
                "${offset}let ${pattern}[${ty}] = ${expr}"
            case ScFuncDecl(f, t) =>
                "TODO" 
            case ScClassDecl(c) => todo()
            case ScRunExpr(e) => todo()
            case ScInterfaceDecl(i) => todo()
        }
    }
}