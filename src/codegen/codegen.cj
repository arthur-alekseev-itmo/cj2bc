package cj2bc.codegen

import cj2bc.simpletree.*
import cj2bc.bytecode.Bytecode
import cj2bc.bytecode.Instruction
import cj2bc.utils.todo
import std.collection.ArrayList
import std.ast.RefExpr

public class Codegen {

    private var branchIndex = 0;
    private func getBranchNextIndex() {
        branchIndex++
    }

    private func createSymbolHere(name: String, state: CodegenState) {
        let idx = Int32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addSymbol(name, idx)
    }

    private func createRelocationHere(name: String, offset: Int32, size: Int32, state: CodegenState) {
        let idx = Int32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addRelocation(name, idx, offset, size)
    }

    private func unableAsRef() {
        throw Exception("Unable to use this expression as ref")
    }

    private func compileLoadUnitTo(state: CodegenState) {
        state.bytecode.addInstruction(LoadImm(0))
    }

    private func compileLoadBoolTo(bool: Bool, state: CodegenState) {
        let asInt = if (bool) { 1 } else { 0 }
        state.bytecode.addInstruction(LoadImm(UInt64(asInt)))
    }

    private func compileLoadConstInt64To(value: Int64, state: CodegenState) {
        state.bytecode.addInstruction(LoadImm(UInt64(value)))
    }

    private func compileIfThenElseTo(cond: SimpleExpr, thenBr: SimpleExpr, elseBr: SimpleExpr, state: CodegenState): Unit {
        let branchIndex = getBranchNextIndex()
        compileExprTo(cond, state)

        state.bytecode.addInstruction(JumpFalse(UInt32.Max))
        createRelocationHere("$BRANCH_ELSE_${branchIndex}", 1, 4, state)

        compileExprTo(thenBr, state)
        state.bytecode.addInstruction(Jump(UInt32.Max))
        createRelocationHere("$BRANCH_END_${branchIndex}", 1, 4, state)
        createSymbolHere("$BRANCH_ELSE_${branchIndex}", state)

        compileExprTo(elseBr, state)
        let elseEndIndex = Int32(state.bytecode.getCurrentInstructionIndex())

        createSymbolHere("$BRANCH_END_${branchIndex}", state)
    }

    private func compileBinaryOperatorTo(op: SimpleBinaryOperator, left: SimpleExpr, right: SimpleExpr, state: CodegenState) {
        compileExprTo(left, state)
        compileExprTo(right, state)
        let instruction = match (op) {
            case Add => Instruction.Add
            case Sub => Instruction.Sub
            case Mul => Instruction.Mul
            case Eq => Instruction.Eq
            case _ => todo()
        }
        state.bytecode.addInstruction(instruction)
    }

    private func compileUnaryOpTo(op: SimpleUnaryOperator, expr: SimpleExpr, state: CodegenState) {
        compileExprTo(expr, state)
        let instruction = match (op) {
            case Neg => Instruction.Neg
            case Not => Instruction.Not
        }
        state.bytecode.addInstruction(instruction)
    }

    private func compileCallTo(callee: SimpleExpr, arguments: ArrayList<SimpleExpr>, state: CodegenState) {
        arguments.map { argument: SimpleExpr => compileExprTo(argument, state) }
        // TODO: Load callee as expr, not as object
        compileExprAsRefTo(callee, state)
    }

    private func compileExprAsRefTo(expr: SimpleExpr, state: CodegenState) {
        match (expr) {
            case ScConstUnit => unableAsRef()
            case ScConstInt64(x) => unableAsRef()
            case ScConstBool(b) => unableAsRef()
            case ScIfThenElse(cond, thenBr, elseBr) => unableAsRef()
            case ScBinaryOperator(op, left, right) => unableAsRef()
            case ScUnaryOperator(op, expr) => todo()
            case ScCall(callee, arguments) => todo()
            case ScBlockExpr(block) => todo()
            case ScReturn(expr) => todo()
            case ScAssign(target, expr) => todo()
            case ScVarRef(v) => todo()
        }
    }

    private func compileBlockTo(block: SimpleBlock, state: CodegenState) {
        todo()
    }

    private func compileReturnTo(returnExpr: SimpleExpr, state: CodegenState) {
        compileExprTo(returnExpr, state)
        state.bytecode.addInstruction(Return)
    }

    private func compileVarTo(name: String, state: CodegenState) {
        // TODO: Proper location fetching
        let localIndex = 0i32
        state.bytecode.addInstruction(LoadLocal(localIndex))
    }

    private func compileAssignTo(target: SimpleExpr, expr: SimpleExpr, state: CodegenState) {
        compileExprAsRefTo(target, state)
        compileExprTo(expr, state)
        state.bytecode.addInstruction(WriteToRef)
    }

    private func compileExprTo(expr: SimpleExpr, state: CodegenState): Unit {
        match (expr) {
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
        }
    }

    private func compileDeclTo(decl: SimpleDecl, state: CodegenState) {
        match (decl) {
            case ScFuncDecl(data) => todo()
            case ScVarDecl(pattern, expr) => todo()
            case ScRunExpr(expr) => todo()
        }
    }

    private func compileProgramTo(program: SimpleProgram, state: CodegenState) {
        program.map { decl: SimpleDecl => compileDeclTo(decl, state) }
    }

    public func compileProgram(program: SimpleProgram) {
        let state = CodegenState()
        compileProgramTo(program, state)
        state
    }
}
