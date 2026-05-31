package cj2bc.simpletree.parser

import cj2bc.simpletree.tree.*
import std.ast.*
import cj2bc.utils.todo
import std.collection.ArrayList
import std.convert.Parsable

public class SimpleExprParser {

    private static func returnTyped(expr: SimpleExpr) {
        TypedExpr(expr, TUnknown)
    }

    private static func translateBinaryExpr(binary: BinaryExpr): TypedExpr {
        let left = translateExpr(binary.leftExpr)
        let right = translateExpr(binary.rightExpr)
        let op = match (binary.op.value) {
            case "+" => SimpleBinaryOperator.Add
            case "-" => SimpleBinaryOperator.Sub
            case "*" => SimpleBinaryOperator.Mul
            case "/" => SimpleBinaryOperator.Div
            case "%" => SimpleBinaryOperator.Mod
            case "<" => SimpleBinaryOperator.Lt
            case "<=" => SimpleBinaryOperator.Le
            case ">" => SimpleBinaryOperator.Gt
            case ">=" => SimpleBinaryOperator.Ge
            case "!=" => SimpleBinaryOperator.Neq
            case "==" => SimpleBinaryOperator.Eq
            case "&&" => SimpleBinaryOperator.And
            case "||" => SimpleBinaryOperator.Or
            case _ => todo()
        }
        returnTyped(ScBinaryOperator(op, left, right))
    }

    private static func translateUnary(unary: UnaryExpr): TypedExpr {
        let expr = translateExpr(unary.expr)
        let op = match (unary.op.value) {
            case "!" => SimpleUnaryOperator.Not
            case "-" => SimpleUnaryOperator.Neg
            case _ => todo()
        }
        returnTyped(ScUnaryOperator(op, expr))
    }

    private static func translateLiteral(literal: LitConstExpr): TypedExpr {
        if (literal.literal.kind == TokenKind.INTEGER_LITERAL) {
            let value = Int64.parse(literal.literal.value)
            return TypedExpr(ScConstInt64(value), TBasic(TInt64))
        }

        if (literal.literal.kind == TokenKind.BOOL_LITERAL) {
            let value = Bool.parse(literal.literal.value)
            return TypedExpr(ScConstBool(value), TBasic(TBool))
        }

        if (literal.literal.kind == TokenKind.UNIT_LITERAL) {
            return TypedExpr(ScConstUnit, TBasic(TUnit))
        }

        todo()
    }

    private static func translateReturn(returnExpr: ReturnExpr): TypedExpr {
        TypedExpr(ScReturn(translateExpr(returnExpr.expr)), TNothing)
    }

    private static func translateAssign(assignExpr: AssignExpr): TypedExpr {
        let left = translateExpr(assignExpr.leftExpr)
        let right = translateExpr(assignExpr.rightExpr)
        TypedExpr(ScAssign(left, right), TBasic(TUnit))
    }

    private static func translateCall(callExpr: CallExpr): TypedExpr {
        let callee = translateExpr(callExpr.callFunc)
        let args = callExpr.arguments.map { argument: Argument =>
            translateExpr(argument.expr)
        }
        returnTyped(ScCall(callee, args))
    }

    private static func translateIfExpr(ifExpr: IfExpr): TypedExpr {
        let condition = translateExpr(ifExpr.condition)
        let thenBranch = SimpleParser.translateBlock(ifExpr.ifBlock)
        let elseBranch = try {
            Some(translateExpr(ifExpr.elseExpr))
        } catch (_) {
            None<TypedExpr>
        }
        let thenBranchBlock = returnTyped(ScBlockExpr(thenBranch))
        returnTyped(ScIfThenElse(condition, thenBranchBlock, elseBranch))
    }

    private static func translateWhile(_: WhileExpr): TypedExpr {
        todo()
    }

    private static func translateDoWhileExpr(_: DoWhileExpr): TypedExpr {
        todo()
    }

    private static func translateForInExpr(_: ForInExpr): TypedExpr {
        todo()
    }

    private static func translateRefExpr(refExpr: RefExpr): TypedExpr {
        if (refExpr.identifier.kind == TokenKind.THIS) {
            return returnTyped(ScVarRef("this"))
        }

        if (refExpr.identifier.kind != TokenKind.IDENTIFIER) {
            refExpr.dump()
            throw Exception("Cannot work with ref values like this")
        }

        let id = refExpr.identifier.value
        returnTyped(ScVarRef(id))
    }

    private static func translateMemberAccess(memberAccess: MemberAccess): TypedExpr {
        let target = translateExpr(memberAccess.baseExpr)
        let member = memberAccess.field.value
        let expr = ScMemberAccess(target, member)
        returnTyped(expr)
    }

    public static func translateExpr(expr: Expr): TypedExpr {
        match (expr) {
            case block: Block => returnTyped(ScBlockExpr(SimpleParser.translateBlock(block)))
            case binary: BinaryExpr => translateBinaryExpr(binary)
            case unary: UnaryExpr => translateUnary(unary)
            case isExpr: IsExpr => todo()
            case asExpr: AsExpr => todo()
            case parens: ParenExpr => translateExpr(parens.parenthesizedExpr)
            case literal: LitConstExpr => translateLiteral(literal)
            case refExpr: RefExpr => translateRefExpr(refExpr)
            case returnExpr: ReturnExpr => translateReturn(returnExpr)
            case throwExpr: ThrowExpr => todo()
            case performExpr: PerformExpr => todo()
            case resumeExpr: ResumeExpr => todo()
            case assignExpr: AssignExpr => translateAssign(assignExpr)
            case callExpr: CallExpr => translateCall(callExpr)
            case memberAccessExpr: MemberAccess => translateMemberAccess(memberAccessExpr)
            case ifExpr: IfExpr => translateIfExpr(ifExpr)
            case letPatternExpr: LetPatternExpr => todo()
            case matchExpr: MatchExpr => todo()
            case whileExpr: WhileExpr => translateWhile(whileExpr)
            case doWhileExpr: DoWhileExpr => translateDoWhileExpr(doWhileExpr)
            case lambdaExpr: LambdaExpr => todo()
            case spawnExpr: SpawnExpr => todo()
            case synchronizedExpr: SynchronizedExpr => todo()
            case trailingClosureExpr: TrailingClosureExpr => todo()
            case typeConvExpr: TypeConvExpr => todo()
            case forInExpr: ForInExpr => translateForInExpr(forInExpr)
            case privitiveTypeExpr: PrimitiveTypeExpr => todo()
            case arrayLiteral: ArrayLiteral => todo()
            case tupleLiteral: TupleLiteral => todo()
            case rangeExpr: RangeExpr => todo()
            case subscriptExpr: SubscriptExpr => todo()
            case jumpExpr: JumpExpr => todo()
            case incOrDecExpr: IncOrDecExpr => todo()
            case tryExpr: TryExpr => todo()
            case optionalExpr: OptionalExpr => todo()
            case quoteToken: QuoteToken => todo()
            case quoteExpr: QuoteExpr => todo()
            case wildcardExpr: WildcardExpr => todo()
            case varrayExpr: VArrayExpr => todo()
            case macroExpandExpr: MacroExpandExpr => todo()
            case _ => throw Exception("Unknown Expr subtype")
        }
    }
}