package cj2bc.bytecode

import std.collection.ArrayList
import cj2bc.bytecode.util.zeroExtend

public class Bytecode <: ToString {
    let instructions = ArrayList<Instruction>();

    public func serializeTo(target: ArrayList<Byte>) {
        for (instruction in instructions) {
            instruction.serializeTo(target)
        }
    }

    public func serialize() {
        let result = ArrayList<Byte>()
        serializeTo(result)
        result
    }

    public func toString() {
        var instructionId = 0;

        // TODO: Use StringBuilder (https://gitcode.com/Cangjie-SIG/stringbuilder)
        var result = ""

        for (instruction in instructions) {
            result += "B_" + zeroExtend(4, instructionId) + " "
            result += instruction.toString()
            result += "\n"
        }
        result
    }

    public func addInstruction(instruction: Instruction) {
        instructions.add(instruction)
    }

    public func getCurrentInstructionIndex() {
        return instructions.size
    }
}

// From vm:
// NOP = 0x0,
// LOAD_IMM = 0x1,
// ADD = 0x2,
// SUB = 0x3,
// MUL = 0x4,
// EQ = 0x5,
// CALL_C_V_U64 = 0x6,
// CALL_C_V_STACK_PTR = 0x7,
// EXIT = 0x8,
// DUP = 0x9,
// DROP = 0xA,
// JUMP = 0xB,
// JUMP_TRUE = 0xC,
// RETURN = 0xD,
// READ_STACK = 0xE,
// WRITE_STACK = 0xF,
// CALL = 0x10,
// SWAP = 0x11,