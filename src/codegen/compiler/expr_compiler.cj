package cj2bc.codegen.compiler

import cj2bc.codegen.CodegenState
import std.collection.ArrayList
import cj2bc.bytecode.Instruction
import cj2bc.simpletree.tree.*
import cj2bc.analysis.typing.types.*
import cj2bc.utils.todo
import cj2bc.codegen.StringHashser

let INT_CLASS_ID = 1u32
let BOOL_CLASS_ID = 2u32

public class ExprCompiler {

    private static func compileLoadUnitTo(state: CodegenState) {
        state.bytecode.addInstruction(LoadImm(0))
        state.bytecode.addInstruction(Instruction.Box(INT_CLASS_ID))
    }

    private static func compileLoadBoolTo(bool: Bool, state: CodegenState) {
        let asInt = if (bool) { 1 } else { 0 }
        state.bytecode.addInstruction(LoadImm(UInt64(asInt)))
        state.bytecode.addInstruction(Instruction.Box(BOOL_CLASS_ID))
    }

    private static func compileLoadConstInt64To(value: Int64, state: CodegenState) {
        state.bytecode.addInstruction(LoadImm(UInt64(value)))
        state.bytecode.addInstruction(Instruction.Box(INT_CLASS_ID))
    }

    private static func compileIfThenElseTo(cond: TypedExpr, thenBr: TypedExpr, elseBr: ?TypedExpr, state: CodegenState): Unit {
        let branchIndex = Utils.getBranchNextIndex()
        compileExprTo(cond, state)
        state.bytecode.addInstruction(Instruction.Not)

        state.bytecode.addInstruction(JumpTrue(UInt32.Max))
        Utils.createRelocationHere("$BRANCH_ELSE_${branchIndex}", 4, 1, state)

        compileExprTo(thenBr, state)
        state.bytecode.addInstruction(Jump(UInt32.Max))
        Utils.createRelocationHere("$BRANCH_END_${branchIndex}", 4, 1, state)
        Utils.createLabelHere("$BRANCH_ELSE_${branchIndex}", state)

        match (elseBr) {
            case Some(e) => compileExprTo(e, state)
            case None => state.bytecode.addInstruction(LoadImm(0))
        }

        Utils.createLabelHere("$BRANCH_END_${branchIndex}", state)
    }

    private static func compileBinaryOperatorTo(op: SimpleBinaryOperator, left: TypedExpr, right: TypedExpr, state: CodegenState) {
        func simple(instruction: String) {
            let operatorCall = StringHashser.getHash(instruction)
            compileExprTo(left, state)
            state.bytecode.addInstruction(GetField(operatorCall))
            compileExprTo(right, state)
            state.bytecode.addInstruction(Swap)
            state.bytecode.addInstruction(CallObject)
        }

        match (op) {
            case Add => simple("+")
            case Sub => simple("-")
            case Mul => simple("*")
            case Div => simple("/")
            case Mod => simple("%")
            case Eq => simple("==")
            case Neq => simple("!=")
            case Le => simple("<=")
            case Lt => simple("<")
            case Ge => simple(">=")
            case Gt => simple(">")
            case BitXor => simple("^")
            case BitAnd => simple("&")
            case BitOr => simple("|")
            case And => compileIfThenElseTo(left, right, TypedExpr(ScConstBool(false), TBasic(TBool)), state)
            case Or => compileIfThenElseTo(left, TypedExpr(ScConstBool(true), TBasic(TBool)), right, state)
        }
    }

    private static func compileUnaryOpTo(op: SimpleUnaryOperator, expr: TypedExpr, state: CodegenState) {
        compileExprTo(expr, state)
        let instruction = match (op) {
            case Neg => Instruction.Neg
            case Not => Instruction.Not
        }
        state.bytecode.addInstruction(instruction)
    }

    private static func compileCallTo(callee: TypedExpr, arguments: ArrayList<TypedExpr>, state: CodegenState) {
        arguments.map { argument: TypedExpr => compileExprTo(argument, state) }
        compileExprTo(callee, state)
        let operatorCall = StringHashser.getHash("()")
        state.bytecode.addInstruction(GetField(operatorCall))
        state.bytecode.addInstruction(Instruction.CallObject)
    }

    private static func compileVarAsRefTo(name: String, state: CodegenState) {
        let variable = state.locals.getVariable(name) ?? throw Exception("Variable was not found: " + name)
        match (variable) {
            case GlobalVariable(x) => state.bytecode.addInstruction(GetGlobalRef(x))
            case LocalVariable(x) => state.bytecode.addInstruction(GetLocalRef(x))
            case ClosureVariable(x) => state.bytecode.addInstruction(GetClosureRef(x))
        }
    }

    private static func compileMemberAccessAsRefTo(target: TypedExpr, member: String, state: CodegenState) {
        let memberHash = StringHashser.getHash(member) 
        compileExprTo(target, state)
        state.bytecode.addInstruction(GetFieldRef(memberHash))
    }

    private static func compileMemberAccessTo(target: TypedExpr, member: String, state: CodegenState) {
        let memberHash = StringHashser.getHash(member)
        compileExprTo(target, state)
        state.bytecode.addInstruction(GetField(memberHash))
    }

    public static func compileExprAsRefTo(expr: TypedExpr, state: CodegenState): Unit {
        match (expr.expr) {
            case ScConstUnit => Utils.unableAsRef()
            case ScConstInt64(x) => Utils.unableAsRef()
            case ScConstBool(b) => Utils.unableAsRef()
            case ScIfThenElse(cond, thenBr, elseBr) => Utils.unableAsRef()
            case ScBinaryOperator(op, left, right) => Utils.unableAsRef()
            case ScUnaryOperator(op, expr) => todo()
            case ScCall(callee, arguments) => todo()
            case ScBlockExpr(block) => todo()
            case ScReturn(expr) => todo()
            case ScAssign(target, expr) => todo()
            case ScVarRef(name) => compileVarAsRefTo(name, state)
            case ScMemberAccess(target, member) => compileMemberAccessAsRefTo(target, member, state)
        }
    }

    public static func compileBlockTo(block: TypedBlock, state: CodegenState): Unit {
        let length = block.size
        for (i in 0..length-1) {
            let decl = block[i]
            DeclCompiler.compileDeclTo(decl, true, state)
        }
        block.last.map { x: TypedDecl => DeclCompiler.compileDeclTo(x, false, state) }
    }

    private static func compileReturnTo(returnExpr: TypedExpr, state: CodegenState) {
        compileExprTo(returnExpr, state)
        state.bytecode.addInstruction(Return)
    }

    private static func compileVarTo(name: String, state: CodegenState) {
        let variable = state.locals.getVariable(name)
        
        let decl = state.scope.findSymbol(name)
        match (decl.decl) {
            case ScClassDecl(c) => 
                let ldclass = LoadClass(StringHashser.getHash(c.name))
                return state.bytecode.addInstruction(ldclass)
            case _ => ()
        }
        
        match (variable) {
            case Some(GlobalVariable(x)) => state.bytecode.addInstruction(LoadGlobal(x))
            case Some(LocalVariable(x)) => state.bytecode.addInstruction(LoadLocal(x))
            case Some(ClosureVariable(x)) => state.bytecode.addInstruction(LoadClosure(x))
            case None =>
                state.bytecode.addInstruction(LoadGlobal(UInt32.Max))
                Utils.createRelocationHere(name, 4, 1, state)
        }
    }

    private static func compileAssignTo(target: TypedExpr, expr: TypedExpr, state: CodegenState) {
        compileExprAsRefTo(target, state)
        compileExprTo(expr, state)
        state.bytecode.addInstruction(WriteToRef)
    }

    public static func compileExprTo(expr: TypedExpr, state: CodegenState): Unit {
        match (expr.expr) {
            case ScConstUnit => compileLoadUnitTo(state)
            case ScConstInt64(x) => compileLoadConstInt64To(x, state)
            case ScConstBool(b) => compileLoadBoolTo(b, state)
            case ScIfThenElse(cond, thenBr, elseBr) => compileIfThenElseTo(cond, thenBr, elseBr, state)
            case ScBinaryOperator(op, left, right) => compileBinaryOperatorTo(op, left, right, state)
            case ScUnaryOperator(op, expr) => compileUnaryOpTo(op, expr, state)
            case ScCall(callee, arguments) => compileCallTo(callee, arguments, state)
            case ScBlockExpr(block) => compileBlockTo(block, state)
            case ScReturn(expr) => compileReturnTo(expr, state)
            case ScAssign(target, expr) => compileAssignTo(target, expr, state)
            case ScVarRef(name) => compileVarTo(name, state)
            case ScMemberAccess(target, member) => compileMemberAccessTo(target, member, state)
        }
    }
}