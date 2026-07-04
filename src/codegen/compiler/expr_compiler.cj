package cj2bc.codegen.compiler

import cj2bc.codegen.state.CodegenState
import std.collection.ArrayList
import cj2bc.bytecode.Instruction
import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.utils.todo
import cj2bc.codegen.state.StringHasher

import cj2bc.prettyprint.PPType

let INT_CLASS_ID = 1u32
let BOOL_CLASS_ID = 2u32

public class ExprCompiler {

    private static func getBasicTypeIndex(typ: BasicType): UInt32 {
        match (typ) {
            case TInt64 => INT_CLASS_ID
            case TBool => BOOL_CLASS_ID
            case TUnit => INT_CLASS_ID
        }
    }

    private static func addBoxingForSimpleTy(typeFrom: Type, typeTo: Type, state: CodegenState) {
        match ((typeFrom, typeTo)) {
            case (TBasic(_), TBasic(_)) => ()
            case (TBasic(x), _) => state.bytecode.addInstruction(Instruction.Box(getBasicTypeIndex(x)))
            case (_, TBasic(x)) => state.bytecode.addInstruction(Instruction.Unbox)
            case _ => ()
        }
    }

    private static func compileLoadUnitTo(state: CodegenState) {
        state.bytecode.addInstruction(LoadImm(0))
    }

    private static func compileLoadBoolTo(bool: Bool, state: CodegenState) {
        let asInt = if (bool) { 1 } else { 0 }
        state.bytecode.addInstruction(LoadImm(UInt64(asInt)))
    }

    private static func compileLoadConstInt64To(value: Int64, state: CodegenState) {
        state.bytecode.addInstruction(LoadImm(UInt64(value)))
    }

    private static func compileIfThenElseTo(cond: TypedExpr, thenBr: TypedExpr, elseBr: ?TypedExpr, state: CodegenState): Unit {
        let branchIndex = Utils.getBranchNextIndex()
        compileExprTo(cond, state)
        addBoxingForSimpleTy(cond.ty, TBasic(TBool), state)
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

    private static func compileBinaryOperatorAsMethodCallTo(op: CjBinaryOperator, left: TypedExpr, right: TypedExpr, state: CodegenState) {
        func simple(instruction: String) {
            let operatorCall = StringHasher.getHash(instruction)
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

    private static func compileBinaryOperatorForPrimitiveTo(op: CjBinaryOperator, left: TypedExpr, right: TypedExpr, state: CodegenState) {
        match (op) {
            case Add => state.bytecode.addInstruction(Instruction.Add)
            case Sub => state.bytecode.addInstruction(Instruction.Sub)
            case Mul => state.bytecode.addInstruction(Instruction.Mul)
            case Div => state.bytecode.addInstruction(Instruction.Div)
            case Mod => state.bytecode.addInstruction(Instruction.Mod)
            case Eq => state.bytecode.addInstruction(Instruction.Eq)
            case Neq => state.bytecode.addInstruction(Instruction.Neq)
            case Le => state.bytecode.addInstruction(Instruction.Le)
            case Lt => state.bytecode.addInstruction(Instruction.Lt)
            case Ge => state.bytecode.addInstruction(Instruction.Ge)
            case Gt => state.bytecode.addInstruction(Instruction.Gt)
            case BitXor => state.bytecode.addInstruction(Instruction.BitXor)
            case BitAnd => state.bytecode.addInstruction(Instruction.BitAnd)
            case BitOr => state.bytecode.addInstruction(Instruction.BitOr)
            case And => compileIfThenElseTo(left, right, TypedExpr(ScConstBool(false), TBasic(TBool)), state)
            case Or => compileIfThenElseTo(left, TypedExpr(ScConstBool(true), TBasic(TBool)), right, state)
        }
    }

    private static func compileBinaryOperatorTo(op: CjBinaryOperator, left: TypedExpr, right: TypedExpr, state: CodegenState) {
        match ((left.ty, right.ty)) {
            case (TBasic(x), TBasic(y)) =>
                // No unboxing and raw operator
                compileExprTo(left, state)
                compileExprTo(right, state)
                compileBinaryOperatorForPrimitiveTo(op, left, right, state)
            case (TBasic(x), _) =>
                // Unboxing required for right and then raw operator
                compileExprTo(left, state)
                compileExprTo(right, state)
                state.bytecode.addInstruction(Instruction.Unbox)
                compileBinaryOperatorForPrimitiveTo(op, left, right, state)
            case (_, _) =>
                // Handle as a method call
                compileBinaryOperatorAsMethodCallTo(op, left, right, state) 
        }
    }

    private static func compileUnaryOpAsMethodCallTo(op: CjUnaryOperator, state: CodegenState) {
        let notHash = StringHasher.getHash("!")
        let negHash = StringHasher.getHash("-unary")
        let instruction = match (op) {
            case Neg => negHash
            case Not => notHash
        }
        state.bytecode.addInstruction(GetField(instruction))
        state.bytecode.addInstruction(CallObject)
    }

    private static func compileUnaryOpForPrimitiveTo(op: CjUnaryOperator, state: CodegenState) {
        let instruction = match (op) {
            case Neg => state.bytecode.addInstruction(Instruction.Neg)
            case Not => state.bytecode.addInstruction(Instruction.Not)
        }
    }

    private static func compileUnaryOpTo(op: CjUnaryOperator, expr: TypedExpr, state: CodegenState) {
       compileExprTo(expr, state)
        match (expr.ty) {
            case TBasic(x) => compileUnaryOpForPrimitiveTo(op, state)
            case _ => compileUnaryOpAsMethodCallTo(op, state)
        }
    }

    private static func compileCallTo(callee: TypedExpr, arguments: ArrayList<TypedExpr>, state: CodegenState) {
        let parameterTypes = match (callee.ty) {
            case TFunction(parameters, out) => parameters
            case x => todo("While calling function, function had type: ${PPType.typeToString(x)}")
        }
        arguments.zip(parameterTypes).map { pair: (TypedExpr, Type) => 
            compileExprTo(pair[0], state)
            addBoxingForSimpleTy(pair[0].ty, pair[1], state)
        }
        compileExprTo(callee, state)
        let operatorCall = StringHasher.getHash("()")
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
        let memberHash = StringHasher.getHash(member) 
        compileExprTo(target, state)
        state.bytecode.addInstruction(GetFieldRef(memberHash))
    }

    private static func compileMemberAccessTo(target: TypedExpr, member: String, state: CodegenState) {
        let memberHash = StringHasher.getHash(member)
        // TODO: Feels like here primitive types might need boxing
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
            case ScCast(_, _) => Utils.unableAsRef()
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
 
    private static func compileCastTo(value: TypedExpr, ty: HierarhicalType, state: CodegenState) {
        compileExprTo(value, state)
        let typeHash = StringHasher.getHash(ty.name)
        state.bytecode.addInstruction(Cast(typeHash))
    }

    private static func compileVarTo(name: String, state: CodegenState) {
        let variable = state.locals.getVariable(name)
        
        let decl = state.scope.findSymbol(name)
        match (decl.decl) {
            case ScClassDecl(c) => 
                let ldclass = LoadClass(StringHasher.getHash(c.name))
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
        addBoxingForSimpleTy(expr.ty, target.ty, state)
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
            case ScCast(target, ty) => compileCastTo(target, ty, state)
            case ScMemberAccess(target, member) => compileMemberAccessTo(target, member, state)
        }
    }
}