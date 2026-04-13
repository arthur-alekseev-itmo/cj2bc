package cj2bc.bytecode

import std.collection.ArrayList
import cj2bc.bytecode.util.zeroExtend

public class Bytecode <: ToString {
    let instructions = ArrayList<Instruction>();

    public func serializeTo(target: ArrayList<Byte>): Unit {
        for (instruction in instructions) {
            instruction.serializeTo(target)
        }
    }

    public func serialize(): ArrayList<Byte> {
        let result = ArrayList<Byte>()
        serializeTo(result)
        result
    }

    public func toString(): String {
        var instructionId = 0
        var result = StringBuilder()

        for (instruction in instructions) {
            result.append("B_" + zeroExtend(4, instructionId) + " ")
            result.append(instruction.toString())
            result.append("\n")
            instructionId++
        }
        result.toString()
    }

    public func addInstruction(instruction: Instruction): Unit {
        instructions.add(instruction)
    }

    public func getCurrentInstructionIndex(): Int64 {
        instructions.size
    }

    public func getInstructionArray() {
        instructions
    }
}