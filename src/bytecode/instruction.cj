package cj2bc.bytecode

import std.collection.ArrayList
import cj2bc.bytecode.util.appendInt64
import cj2bc.bytecode.util.appendInt32

public enum Instruction <: ToString {
    | Nop
    | LoadImm(UInt64)
    | Add
    | Sub
    | Mul
    | Div
    | Mod
    | Eq
    | Neq
    | Le
    | Ge
    | Lt
    | Gt
    | BitXor
    | BitAnd
    | BitOr
    | And
    | Or
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
    | WriteStack(UInt32)
    | AllocateLocals(UInt32)
    | LoadLocal(UInt32)
    | LoadGlobal(UInt32)
    | LoadClosure(UInt32)
    | StoreLocal(UInt32)
    | StoreGlobal(UInt32)
    | StoreClosure(UInt32)
    | GetLocalRef(UInt32)
    | GetGlobalRef(UInt32)
    | GetClosureRef(UInt32)
    | Call(UInt32)
    | CallObject
    | CallBuiltin(UInt32)
    | Swap
    | Neg
    | Not
    | WriteToRef
    | FunctionAddress(UInt32)
    | New(UInt32)
    | GetFieldRef(UInt32)
    | GetField(UInt32)
    // | CallMethod(UInt32)
    // | GetMethod(UInt32)
    | Box(UInt32)
    | Unbox
    | LoadClass(UInt32)

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

    // TODO: Sort neatly
    public func serializeTo(target: ArrayList<Byte>): Unit {
        match (this) {
            case Nop => addCommand0To(0x0, target)
            case LoadImm(x) => addCommand64To(0x1, x, target)
            case Add => addCommand0To(0x2, target)
            case Sub => addCommand0To(0x3, target)
            case Mul => addCommand0To(0x4, target)
            case Div => addCommand0To(0x5, target)
            case Mod => addCommand0To(0x6, target)
            case Eq => addCommand0To(0x7, target)
            case Neq => addCommand0To(0x8, target)
            case Le => addCommand0To(0x9, target)
            case Ge => addCommand0To(0xa, target)
            case Lt => addCommand0To(0xb, target)
            case Gt => addCommand0To(0xc, target)
            case BitXor => addCommand0To(0xd, target)
            case BitAnd => addCommand0To(0xe, target)
            case BitOr => addCommand0To(0xf, target)
            case And => addCommand0To(0x10, target)
            case Or => addCommand0To(0x11, target)
            case CallCVU64(x) => addCommand64To(0x12, x, target)
            case CallCVStackPtr(x) => addCommand64To(0x13, x, target)
            case Exit => addCommand0To(0x14, target)
            case Dup => addCommand0To(0x15, target)
            case Drop => addCommand0To(0x16, target)
            case Jump(x) => addCommand32To(0x17, x, target)
            case JumpTrue(x) => addCommand32To(0x18, x, target)
            case JumpFalse(x) => addCommand32To(0x19, x, target)
            case Return => addCommand0To(0x1a, target)
            case ReadStack(x) => addCommand32To(0x1b, x, target)
            case WriteStack(x) => addCommand32To(0x1c, x, target)
            case LoadLocal(x) => addCommand32To(0x1d, x, target)
            case LoadGlobal(x) => addCommand32To(0x1e, x, target)
            case LoadClosure(x) => addCommand32To(0x1f, x, target)
            case StoreLocal(x) => addCommand32To(0x20, x, target)
            case StoreGlobal(x) => addCommand32To(0x21, x, target)
            case StoreClosure(x) => addCommand32To(0x22, x, target)
            case GetLocalRef(x) => addCommand32To(0x23, x, target)
            case GetGlobalRef(x) => addCommand32To(0x24, x, target)
            case GetClosureRef(x) => addCommand32To(0x25, x, target)
            case AllocateLocals(x) => addCommand32To(0x26, x, target)
            case Call(x) => addCommand32To(0x27, x, target)
            case CallObject => addCommand0To(0x28, target)
            case CallBuiltin(x) => addCommand32To(0x29, x, target)
            case Swap => addCommand0To(0x2a, target)
            case Neg => addCommand0To(0x2b, target)
            case Not => addCommand0To(0x2c, target)
            case WriteToRef => addCommand0To(0x2d, target)
            case FunctionAddress(x) => addCommand32To(0x2e, x, target)
            case New(x) => addCommand32To(0x2f, x, target)
            case GetFieldRef(x) => addCommand32To(0x30, x, target)
            case GetField(x) => addCommand32To(0x31, x, target)
            case Box(x) => addCommand32To(0x32, x, target)
            case Unbox => addCommand0To(0x33, target)
            case LoadClass(x) => addCommand32To(0x34, x, target)
        }
    }

    public func toString(): String {
        return match (this) {
            case Nop => "Nop"
            case LoadImm(x) => "LoadImm ${x}"
            case Add => "Add"
            case Sub => "Sub"
            case Mul => "Mul"
            case Div => "Div"
            case Mod => "Mod"
            case Eq => "Eq"
            case Neq => "Neq"
            case Le => "Le"
            case Ge => "Ge"
            case Lt => "Lt"
            case Gt => "Gt"
            case BitXor => "BitXor"
            case BitAnd => "BitAnd"
            case BitOr => "BitOr"
            case And => "And"
            case Or => "Or"
            case CallCVU64(x) => "CallCVU64 ${x}"
            case CallCVStackPtr(x) => "CallCVStackPtr ${x}"
            case Exit => "Exit"
            case Dup => "Dup"
            case Drop => "Drop"
            case Jump(x) => "Jump ${x}"
            case JumpTrue(x) => "JumpTrue ${x}"
            case JumpFalse(x) => "JumpTrue ${x}"
            case Return => "Return"
            case ReadStack(x) => "ReadStack ${x}"
            case WriteStack(x) => "WriteStack ${x}"
            case LoadLocal(x) => "LoadLocal ${x}"
            case LoadGlobal(x) => "LoadGlobal ${x}"
            case LoadClosure(x) => "LoadClosure ${x}"
            case StoreLocal(x) => "StoreLocal ${x}"
            case StoreGlobal(x) => "StoreGlobal ${x}"
            case StoreClosure(x) => "StoreClosure ${x}"
            case GetLocalRef(x) => "GetLocalRef ${x}"
            case GetGlobalRef(x) => "GetGlobalRef ${x}"
            case GetClosureRef(x) => "GetClosureRef ${x}"
            case AllocateLocals(x) => "AllocateLocals ${x}"
            case Call(x) => "Call ${x}"
            case CallObject => "CallRef"
            case CallBuiltin(x) => "CallBuiltin ${x}"
            case Swap => "Swap"
            case Neg => "Neg"
            case Not => "Not"
            case WriteToRef => "WriteToRef"
            case FunctionAddress(x) => "FunctionAddress ${x}"
            case New(x) => "Gew ${x}"
            case GetField(x) => "GetField ${x}"
            case GetFieldRef(x) => "GetFieldRef ${x}"
            // case CallMethod(x) => "CallMethod ${x}"
            // case GetMethod(x) => "GetMethod ${x}"
            case Box(x) => "Box ${x}"
            case Unbox => "Unbox"
            case LoadClass(x) => "LoadClass ${x}"
        }
    }
}
