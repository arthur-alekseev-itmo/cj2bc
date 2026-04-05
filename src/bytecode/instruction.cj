package cj2bc.bytecode

import std.collection.ArrayList
import cj2bc.bytecode.util.*

public enum Instruction <: ToString {
    // TODO: Refresh in CPP
    | Nop
    | LoadImm(UInt64)
    | Add
    | Sub
    | Mul
    | Div
    | Eq
    | Neq
    | Le
    | Ge
    | Lt
    | Gt
    | CallCVU64(UInt64)
    | CallCVStackPtr(UInt64)
    | Exit
    | Dup
    | Drop
    | Jump(UInt32)
    | JumpTrue(UInt32)
    | JumpFalse(UInt32)
    | Return
    | ReadStack(UInt32)
    | WriteStack(UInt64)
    | AllocateLocals(Int32)
    | LoadLocal(Int32)
    | GetLocalRef(Int32)
    | Call(UInt32)
    | CallObject
    | Swap
    | Neg
    | Not
    | WriteToRef


    public func serializeTo(target: ArrayList<Byte>) {
        match (this) {
            case LoadImm(x) => target.add(1); appendInt64(x, target)
            case Add => target.add(2)
            case _ => throw Exception("todo")
        }
    }

    public func toString() {
        match (this) {
            case Nop => return "Nop"
            case LoadImm(x) => return "LoadImm ${x}"
            case Add => return "Add"
            case Sub => return "Sub"
            case Mul => return "Mul"
            case Div => return "Div"
            case Eq => return "Eq"
            case Neq => return "Neq"
            case Le => return "Le"
            case Ge => return "Ge"
            case Lt => return "Lt"
            case Gt => return "Gt"
            case CallCVU64(x) => return "CallCVU64 ${x}"
            case CallCVStackPtr(x) => return "CallCVStackPtr ${x}"
            case Exit => return "Exit"
            case Dup => return "Dup"
            case Drop => return "Drop"
            case Jump(x) => return "Jump ${x}"
            case JumpTrue(x) => return "JumpTrue ${x}"
            case JumpFalse(x) => return "JumpTrue ${x}"
            case Return => return "Return"
            case ReadStack(x) => return "ReadStack ${x}"
            case WriteStack(x) => return "WriteStack ${x}"
            case LoadLocal(x) => return "LoadLocal ${x}"
            case GetLocalRef(x) => return "GetLocalRef ${x}"
            case AllocateLocals(x) => return "AllocateLocals ${x}"
            case Call(x) => return "Call ${x}"
            case CallObject => return "CallRef"
            case Swap => return "Swap"
            case Neg => return "Neg"
            case Not => return "Not"
            case WriteToRef => return "WriteToRef"
        }
    }
}