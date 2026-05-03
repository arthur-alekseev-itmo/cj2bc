package cj2bc.simpletree.pp

import cj2bc.simpletree.tree.*
import cj2bc.utils.todo
import cj2bc.analysis.typing.types.*

public class PpSimpleTree {
    static let LEAP = "   "

    public static func programToString(program: SimpleProgram): String {
        let declStrings = program.map { d => declToString(d, "") }
        String.join(declStrings.toArray(), delimiter:"\n")
    }

    private static func binopToString(op: SimpleBinaryOperator) {
        match (op) {
            case Add => "+"
            case Sub => "-"
            case Mul => "*"
            case Div => "/"
            case Mod => "%"
            case Lt => "<"
            case Le => "<="
            case Gt => ">"
            case Ge => ">="
            case Neq => "!="
            case Eq => "=="
            case And => "&&"
            case Or => "||"
            case BitXor => "^"
            case BitAnd => "&" 
            case BitOr => "|"
        }
    }

    private static func unopToString(op: SimpleUnaryOperator) {
        match (op) {
            case SimpleUnaryOperator.Neg => "-"
            case SimpleUnaryOperator.Not => "!"
        }
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

    private static func simpleTypeToString(t: SimpleType): String {
        match (t) {
            case StPrimitive(StBool) => "StBool"
            case StPrimitive(StUInt64) => "StInt64"
            case StPrimitive(StUnit) => "StUnit"
            case StRefType(r) =>
                let name = r.name
                let argStrings = r.arguments.map(simpleTypeToString)
                let args = String.join(argStrings.toArray(), delimiter:", ")
                let argsBr = if (args.size > 0) { "<${args}>" } else { "" }
                "${name}${argsBr}"
            case StFuncType(p) =>
                let paramStrings = p.parameters.map(simpleTypeToString)
                let returnTy = simpleTypeToString(p.result)
                "(${paramStrings}) -> ${returnTy}"
        }
    }

    private static func typeToString(t: Type) {
        return "TY?"
    }

    private static func patternToString(pattern: SimplePattern) {
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
                let pattern = patternToString(v)
                let expr = exprToString(e, offset)
                let ty = t.map(typeToString).getOrDefault { "" }
                "${offset}let ${pattern}[${ty}] = ${expr}"
            case ScFuncDecl(f, t) =>
                let paramStrings = f.parameters.map(patternToString)
                let params = String.join(paramStrings.toArray(), delimiter:", ")
                let body = blockToString(f.body, offset)
                let ty = t.map(typeToString).getOrDefault { "" }
                "${offset}func ${f.name}(${params})[${ty}] ${body}"
            case ScClassDecl(c) => 
                let body = blockToString(c.innerDecls, offset)
                let superTypeStrings = c.superTypes.map { c => simpleTypeToString(c) }
                let superTypes = String.join(superTypeStrings.toArray(), delimiter:" & ")
                "${offset}class ${c.name} <: ${superTypes} ${body}"
            case ScRunExpr(e) =>
                let expr = exprToString(e, offset)
                "${offset}${expr}"
            case ScInterfaceDecl(i) =>
                let body = blockToString(i.innerDecls, offset)
                let superTypeStrings = i.superTypes.map { c => simpleTypeToString(c) }
                let superTypes = String.join(superTypeStrings.toArray(), delimiter:" & ")
                "${offset}interface ${i.name} <: ${superTypes}"
        }
    }
}