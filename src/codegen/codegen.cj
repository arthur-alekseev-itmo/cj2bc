package cj2bc.codegen

import cj2bc.simpletree.tree.*
import cj2bc.bytecode.Bytecode
import cj2bc.bytecode.Instruction
import cj2bc.utils.todo
import std.collection.ArrayList
import cj2bc.analysis.typing.types.*

public class Codegen {
    private var branchIndexCounter = 0;
    private func getBranchNextIndex() {
        branchIndexCounter++
        branchIndexCounter
    }

    private func createFunctionHere(name: String, state: CodegenState) {
        let idx = UInt32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addSymbol(name, LocGlobalFunction(idx))
    }

    private func createLabelHere(name: String, state: CodegenState) {
        let idx = UInt32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addSymbol(name, LocLabel(idx))
    }

    private func createGlobalHere(name: String, state: CodegenState) {
        let idx = UInt32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addSymbol(name, LocGlobalVariable(idx))
    }

    private func createRelocationHere(name: String, size: Int32, offset: Int32, state: CodegenState) {
        let idx = Int32(state.bytecode.getCurrentInstructionIndex() - 1)
        state.linkerData.addRelocation(name, idx, size, offset)
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

    private func compileIfThenElseTo(cond: TypedExpr, thenBr: TypedExpr, elseBr: ?TypedExpr, state: CodegenState): Unit {
        let branchIndex = getBranchNextIndex()
        compileExprTo(cond, state)
        state.bytecode.addInstruction(Instruction.Not)

        state.bytecode.addInstruction(JumpTrue(UInt32.Max))
        createRelocationHere("$BRANCH_ELSE_${branchIndex}", 4, 1, state)

        compileExprTo(thenBr, state)
        state.bytecode.addInstruction(Jump(UInt32.Max))
        createRelocationHere("$BRANCH_END_${branchIndex}", 4, 1, state)
        createLabelHere("$BRANCH_ELSE_${branchIndex}", state)

        match (elseBr) {
            case Some(e) => compileExprTo(e, state)
            case None => state.bytecode.addInstruction(LoadImm(0))
        }

        let elseEndIndex = Int32(state.bytecode.getCurrentInstructionIndex())

        createLabelHere("$BRANCH_END_${branchIndex}", state)
    }

    private func compileBinaryOperatorTo(op: SimpleBinaryOperator, left: TypedExpr, right: TypedExpr, state: CodegenState) {
        func simple(instruction: Instruction) {
            compileExprTo(left, state)
            compileExprTo(right, state)
            state.bytecode.addInstruction(instruction)
        }

        let instruction = match (op) {
            case Add => simple(Instruction.Add)
            case Sub => simple(Instruction.Sub)
            case Mul => simple(Instruction.Mul)
            case Div => simple(Instruction.Div)
            case Mod => simple(Instruction.Mod)
            case Eq => simple(Instruction.Eq)
            case Neq => simple(Instruction.Neq)
            case Le => simple(Instruction.Le)
            case Lt => simple(Instruction.Lt)
            case Ge => simple(Instruction.Ge)
            case Gt => simple(Instruction.Gt)
            case BitXor => simple(Instruction.BitXor)
            case BitAnd => simple(Instruction.BitAnd)
            case BitOr => simple(Instruction.BitOr)
            case And => compileIfThenElseTo(left, right, TypedExpr(ScConstBool(false), TBasic(TBool)), state)
            case Or => compileIfThenElseTo(left, TypedExpr(ScConstBool(true), TBasic(TBool)), right, state)
        }
    }

    private func compileUnaryOpTo(op: SimpleUnaryOperator, expr: TypedExpr, state: CodegenState) {
        compileExprTo(expr, state)
        let instruction = match (op) {
            case Neg => Instruction.Neg
            case Not => Instruction.Not
        }
        state.bytecode.addInstruction(instruction)
    }

    private func compileCallTo(callee: TypedExpr, arguments: ArrayList<TypedExpr>, state: CodegenState) {
        arguments.map { argument: TypedExpr => compileExprTo(argument, state) }
        compileExprTo(callee, state)
        state.bytecode.addInstruction(Instruction.CallObject)
    }

    private func compileVarAsRefTo(name: String, state: CodegenState) {
        let variable = state.locals.getVariable(name) ?? throw Exception("Variable was not found: " + name)
        match (variable) {
            case GlobalVariable(x) => state.bytecode.addInstruction(GetGlobalRef(x))
            case LocalVariable(x) => state.bytecode.addInstruction(GetLocalRef(x))
            case ClosureVariable(x) => state.bytecode.addInstruction(GetClosureRef(x))
        }
    }

    private func compileExprAsRefTo(expr: TypedExpr, state: CodegenState) {
        match (expr.expr) {
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
            case ScVarRef(name) => compileVarAsRefTo(name, state)
        }
    }

    private func compileBlockTo(block: TypedBlock, state: CodegenState): Unit {
        let length = block.size
        for (i in 0..length-1) {
            let decl = block[i]
            compileDeclTo(decl, true, state)
        }
        block.last.map { x: TypedDecl => compileDeclTo(x, false, state) }
    }

    private func compileReturnTo(returnExpr: TypedExpr, state: CodegenState) {
        compileExprTo(returnExpr, state)
        state.bytecode.addInstruction(Return)
    }

    private func compileVarTo(name: String, state: CodegenState) {
        let variable = state.locals.getVariable(name)
        match (variable) {
            case Some(GlobalVariable(x)) => state.bytecode.addInstruction(LoadGlobal(x))
            case Some(LocalVariable(x)) => state.bytecode.addInstruction(LoadLocal(x))
            case Some(ClosureVariable(x)) => state.bytecode.addInstruction(LoadClosure(x))
            case None =>
                state.bytecode.addInstruction(LoadGlobal(UInt32.Max))
                createRelocationHere(name, 4, 1, state)
        }
    }

    private func compileAssignTo(target: TypedExpr, expr: TypedExpr, state: CodegenState) {
        compileExprAsRefTo(target, state)
        compileExprTo(expr, state)
        state.bytecode.addInstruction(WriteToRef)
    }

    private func compileExprTo(expr: TypedExpr, state: CodegenState): Unit {
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
        }
    }

    private func storePatternTo(pattern: SimplePattern, state: CodegenState) {
        match (pattern) {
            case ScVariable(name, _) =>
                let variable = state.locals.addVariable(name)
                match (variable) {
                    case GlobalVariable(x) => state.bytecode.addInstruction(StoreGlobal(x))
                    case LocalVariable(x) => state.bytecode.addInstruction(StoreLocal(x))
                    case ClosureVariable(x) => state.bytecode.addInstruction(StoreClosure(x))
                }
        }
    }

    private func compileFunDeclTo(decl: FuncDeclData, state: CodegenState) {
        createFunctionHere(decl.name, state)
        state.pushLocalsFrame()
        for (parameter in decl.parameters) {
            storePatternTo(parameter, state)
        }
        compileBlockTo(decl.body, state)
        state.popLocalsFrame()
    }

    private func compileVarDeclTo(pattern: SimplePattern, expr: TypedExpr, state: CodegenState) {
        compileExprTo(expr, state)
        storePatternTo(pattern, state)
    }

    private func compileRunExprTo(expr: TypedExpr, ignoreResult: Bool, state: CodegenState) {
        compileExprTo(expr, state)
        if (ignoreResult) {
            state.bytecode.addInstruction(Drop)
        }
    }

    private func compileDeclTo(decl: TypedDecl, ignoreResult: Bool, state: CodegenState) {
        match (decl.decl) {
            case ScFuncDecl(data) => compileFunDeclTo(data, state)
            case ScVarDecl(pattern, expr) => compileVarDeclTo(pattern, expr, state)
            case ScRunExpr(expr) => compileRunExprTo(expr, ignoreResult, state)
            case _ => todo()
        }
    }

    private func compileProgramTo(program: SimpleProgram, state: CodegenState) {
       program.map { decl: TypedDecl => compileDeclTo(decl, true, state) }
    }

    private func appendBuiltinsTo(state: CodegenState) {
        // println(x) {
        //   builin_print(x)
        // }
        createFunctionHere("println", state)
        state.bytecode.addInstruction(CallBuiltin(0))
        state.bytecode.addInstruction(LoadImm(0))
        state.bytecode.addInstruction(Return)
    }

    public func compileProgram(program: SimpleProgram): CodegenState {
        let state = CodegenState()
        compileProgramTo(program, state)
        appendBuiltinsTo(state)
        state
    }
}
