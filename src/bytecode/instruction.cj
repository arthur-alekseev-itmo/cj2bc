package cj2bc.bytecode

import std.collection.ArrayList
import cj2bc.bytecode.util.appendInt64
import cj2bc.bytecode.util.appendInt32

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
    | AllocateLocals(UInt32)
    | LoadLocal(UInt32)
    | StoreLocal(UInt32)
    | GetLocalRef(UInt32)
    | Call(UInt32)
    | CallObject
    | Swap
    | Neg
    | Not
    | WriteToRef

    private func addCommand0To(tag: Byte, target: ArrayList<Byte>): Unit {
        target.add(tag)
    }

    private func addCommand32To(tag: Byte, arg: UInt32, target: ArrayList<Byte>): Unit {
        target.add(tag)
        appendInt32(arg, target)
    }

    private func addCommand64To(tag: Byte, arg: UInt64, target: ArrayList<Byte>): Unit {
        target.add(tag)
        appendInt64(arg, target)
    }


    public func serializeTo(target: ArrayList<Byte>): Unit {
        match (this) {
            case Nop => addCommand0To(0x0, target)
            case LoadImm(x) => addCommand64To(0x1, x, target)
            case Add => addCommand0To(0x2, target)
            case Sub => addCommand0To(0x3, target)
            case Mul => addCommand0To(0x4, target)
            case Div => addCommand0To(0x5, target)
            case Eq => addCommand0To(0x6, target)
            case Neq => addCommand0To(0x7, target)
            case Le => addCommand0To(0x8, target)
            case Ge => addCommand0To(0x9, target)
            case Lt => addCommand0To(0xa, target)
            case Gt => addCommand0To(0xb, target)
            case CallCVU64(x) => addCommand64To(0xc, x, target)
            case CallCVStackPtr(x) => addCommand64To(0xd, x, target)
            case Exit => addCommand0To(0xe, target)
            case Dup => addCommand0To(0xf, target)
            case Drop => addCommand0To(0x10, target)
            case Jump(x) => addCommand32To(0x11, x, target)
            case JumpTrue(x) => addCommand32To(0x12, x, target)
            case JumpFalse(x) => addCommand32To(0x13, x, target)
            case Return => addCommand0To(0x14, target)
            case ReadStack(x) => addCommand32To(0x15, x, target)
            case WriteStack(x) => addCommand64To(0x16, x, target)
            case LoadLocal(x) => addCommand32To(0x17, x, target)
            case StoreLocal(x) => addCommand32To(0x18, x, target)
            case GetLocalRef(x) => addCommand32To(0x19, x, target)
            case AllocateLocals(x) => addCommand32To(0x1a, x, target)
            case Call(x) => addCommand32To(0x1b, x, target)
            case CallObject => addCommand0To(0x1c, target)
            case Swap => addCommand0To(0x1d, target)
            case Neg => addCommand0To(0x1e, target)
            case Not => addCommand0To(0x1f, target)
            case WriteToRef => addCommand0To(0x20, target)
        }
    }

    public func toString(): String {
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
            case StoreLocal(x) => return "StoreLocal ${x}"
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