package cj2bc.simpletree

import std.ast.*
import cj2bc.utils.todo
import std.collection.ArrayList
import std.convert.Parsable

public class SimpleParser {
    public func parse(input: String) {
        let tokens = cangjieLex(input)
        let program = parseProgram(tokens)
        return program.decls.map { decl: Decl =>
            translateDecl(decl)
        }
    }

    private func translateBinaryExpr(binary: BinaryExpr): SimpleExpr {
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
        ScBinaryOperator(op, left, right)
    }

    private func translateUnary(unary: UnaryExpr): SimpleExpr {
        let expr = translateExpr(unary.expr)
        let op = match (unary.op.value) {
            case "!" => SimpleUnaryOperator.Not
            case "-" => SimpleUnaryOperator.Neg
            case _ => todo()
        }
        ScUnaryOperator(op, expr)
    }

    private func translateLiteral(literal: LitConstExpr): SimpleExpr {
        if (literal.literal.kind == TokenKind.INTEGER_LITERAL) {
            let value = Int64.parse(literal.literal.value)
            return ScConstInt64(value)
        }

        if (literal.literal.kind == TokenKind.BOOL_LITERAL) {
            let value = Bool.parse(literal.literal.value)
            return ScConstBool(value)
        }

        todo()
    }

    private func translateReturn(returnExpr: ReturnExpr): SimpleExpr {
        ScReturn(translateExpr(returnExpr.expr))
    }

    private func translateAssign(assignExpr: AssignExpr): SimpleExpr {
        let left = translateExpr(assignExpr.leftExpr)
        let right = translateExpr(assignExpr.rightExpr)
        ScAssign(left, right)
    }

    private func translateCall(callExpr: CallExpr): SimpleExpr {
        let callee = translateExpr(callExpr.callFunc)
        let args = callExpr.arguments.map { argument: Argument =>
            translateExpr(argument.expr)
        }
        ScCall(callee, args)
    }

    private func translateIfExpr(ifExpr: IfExpr): SimpleExpr {
        let condition = translateExpr(ifExpr.condition)
        let thenBranch = translateBlock(ifExpr.ifBlock)
        // TODO: Шедевр я не могу
        let elseBranch = try {
            Some(translateExpr(ifExpr.elseExpr))
        } catch (_) {
            None<SimpleExpr>
        }
        ScIfThenElse(condition, ScBlockExpr(thenBranch), elseBranch)
    }

    private func translateWhile(whileExpr: WhileExpr): SimpleExpr {
        todo()
    }

    private func translateDoWhileExpr(doWhileExpr: DoWhileExpr): SimpleExpr {
        todo()
    }

    private func translateForInExpr(forInEpxr: ForInExpr): SimpleExpr {
        todo()
    }

    private func translateRefExpr(refExpr: RefExpr): SimpleExpr {
        if (refExpr.identifier.kind != TokenKind.IDENTIFIER) {
            throw Exception("Cannot work with ref values like this")
        }

        let id = refExpr.identifier.value
        ScVarRef(id)
    }

    private func translateExpr(expr: Expr): SimpleExpr {
        match (expr) {
            case block: Block => ScBlockExpr(translateBlock(block))
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
            case memberAccessExpr: MemberAccess => todo()
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

    private func translateNode(node: Node): SimpleDecl {
        match (node) {
            case expr: Expr => ScRunExpr(translateExpr(expr))
            case decl: Decl => translateDecl(decl)
            case _ => todo()
        }
    }

    private func translateBlock(block: Block): SimpleBlock {
        block.nodes.map(translateNode)
    }

    private func translateFuncDecl(funcDecl: FuncDecl): SimpleDecl {
        let parameters = funcDecl.funcParams.map { param: FuncParam =>
            // TODO: More stuff, for instance types, annotations etc
            ScVariable(param.identifier.value)
        }
        let body = translateBlock(funcDecl.block)
        ScFuncDecl(FuncDeclData(funcDecl.identifier.value, parameters, body))
    }

    private func translateMainDecl(mainDecl: MainDecl) {
        let funcDecl = FuncDecl()
        funcDecl.identifier = mainDecl.identifier
        funcDecl.funcParams = mainDecl.funcParams
        funcDecl.block = mainDecl.block
        return translateFuncDecl(funcDecl)
    }

    private func translatePattern(pattern: Pattern): SimplePattern {
        match (pattern) {
            case constPattern: ConstPattern => todo()
            case wildcardPattern: WildcardPattern => todo()
            case varPattern: VarPattern => ScVariable(varPattern.identifier.value)
            case varOrEnumPattern: VarOrEnumPattern => todo()
            case exceptTypePattern: ExceptTypePattern => todo()
            case commandTypePattern: CommandTypePattern => todo()
            case typePattern: TypePattern => todo()
            case enumPattern: EnumPattern => todo()
            case tuplePattern: TuplePattern => todo()
            case _ => throw Exception("Unknown Pattern subtype")
        }
    }

    private func translateVarDecl(varDecl: VarDecl): SimpleDecl {
        // TODO: I dunno when can I use pattern, and when I can use identifier
        // let pattern = translatePattern(varDecl.pattern)
        let pattern = ScVariable(varDecl.identifier.value)
        let expr = translateExpr(varDecl.expr)
        ScVarDecl(pattern, expr)
    }

    private func translateDecl(decl: Decl): SimpleDecl {
        match (decl) {
            case classDecl: ClassDecl => todo()
            case structDecl: StructDecl => todo()
            case interfaceDecl: InterfaceDecl => todo()
            case enumDecl: EnumDecl => todo()
            case extendDecl: ExtendDecl => todo()
            case funcDecl: FuncDecl => translateFuncDecl(funcDecl)
            case mainDecl: MainDecl => translateMainDecl(mainDecl)
            case macroDecl: MacroDecl => todo()
            case primaryCtorDecl: PrimaryCtorDecl => todo()
            case varDecl: VarDecl => translateVarDecl(varDecl)
            case funcParamDecl: FuncParam => todo()
            case propDecl: PropDecl => todo()
            case typeAliasDecl: TypeAliasDecl => todo()
            case macroExpandDecl: MacroExpandDecl => todo()
            case _ => throw Exception("Unknown Decl subtype")
        }
    }
}

