package cj2bc.codegen

import cj2bc.simpletree.*
import cj2bc.bytecode.Bytecode
import cj2bc.bytecode.Instruction
import cj2bc.utils.todo
import std.collection.ArrayList

public class Codegen {
    private var branchIndex = 0;
    private func getBranchNextIndex() {
        branchIndex++
        branchIndex
    }

    private func createSymbolHere(name: String, state: CodegenState) {
        let idx = Int32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addSymbol(name, idx)
    }

    private func createRelocationHere(name: String, offset: Int32, size: Int32, state: CodegenState) {
        let idx = Int32(state.bytecode.getCurrentInstructionIndex() - 1)
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

    private func compileIfThenElseTo(cond: SimpleExpr, thenBr: SimpleExpr, elseBr: ?SimpleExpr, state: CodegenState): Unit {
        let branchIndex = getBranchNextIndex()
        compileExprTo(cond, state)

        state.bytecode.addInstruction(JumpFalse(UInt32.Max))
        createRelocationHere("$BRANCH_ELSE_${branchIndex}", 4, 1, state)

        compileExprTo(thenBr, state)
        state.bytecode.addInstruction(Jump(UInt32.Max))
        createRelocationHere("$BRANCH_END_${branchIndex}", 4, 1, state)
        createSymbolHere("$BRANCH_ELSE_${branchIndex}", state)

        match (elseBr) {
            case Some(e) => compileExprTo(e, state)
            case None => ()
        }

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
            case Div => Instruction.Div
            case Eq => Instruction.Eq
            case Le => Instruction.Le
            case Lt => Instruction.Lt
            case Ge => Instruction.Ge
            case Gt => Instruction.Gt
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
        compileExprTo(callee, state)
        arguments.map { argument: SimpleExpr => compileExprTo(argument, state) }
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
            case ScVarRef(name) => compileVarAsRefTo(name, state)
        }
    }

    private func compileBlockTo(block: SimpleBlock, state: CodegenState): Unit {
        for (decl in block) {
            compileDeclTo(decl, state)
        }
    }

    private func compileReturnTo(returnExpr: SimpleExpr, state: CodegenState) {
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
                createRelocationHere(name, 1, 4, state)
        }
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

    private func storePatternTo(pattern: SimplePattern, state: CodegenState) {
        match (pattern) {
            case ScVariable(name) =>
                let variable = state.locals.addVariable(name)
                match (variable) {
                    case GlobalVariable(x) => state.bytecode.addInstruction(StoreGlobal(x))
                    case LocalVariable(x) => state.bytecode.addInstruction(StoreLocal(x))
                    case ClosureVariable(x) => state.bytecode.addInstruction(StoreClosure(x))
                }
        }
    }

    private func compileFunDeclTo(decl: FuncDeclData, state: CodegenState) {
        createSymbolHere(decl.name, state)
        state.pushLocalsFrame()
        for (parameter in decl.parameters) {
            storePatternTo(parameter, state)
        }
        compileBlockTo(decl.body, state)
        state.popLocalsFrame()
    }

    private func compileVarDeclTo(pattern: SimplePattern, expr: SimpleExpr, state: CodegenState) {
        compileExprTo(expr, state)
        storePatternTo(pattern, state)
    }

    private func compileRunExprTo(expr: SimpleExpr, state: CodegenState) {
        compileExprTo(expr, state)
        state.bytecode.addInstruction(Drop)
    }

    private func compileDeclTo(decl: SimpleDecl, state: CodegenState) {
        match (decl) {
            case ScFuncDecl(data) => compileFunDeclTo(data, state)
            case ScVarDecl(pattern, expr) => compileVarDeclTo(pattern, expr, state)
            case ScRunExpr(expr) => compileRunExprTo(expr, state)
        }
    }

    private func compileProgramTo(program: SimpleProgram, state: CodegenState) {
       program.map { decl: SimpleDecl => compileDeclTo(decl, state) }
    }

    private func appendBuiltinsTo(state: CodegenState) {
        // print(x) {
        //   builin_print(x)
        // }
        createSymbolHere("print", state)
        state.bytecode.addInstruction(LoadLocal(0))
        state.bytecode.addInstruction(CallBuiltin(0))
        state.bytecode.addInstruction(Return)
    }

    public func compileProgram(program: SimpleProgram): CodegenState {
        let state = CodegenState()
        compileProgramTo(program, state)
        appendBuiltinsTo(state)
        state
    }
  }
