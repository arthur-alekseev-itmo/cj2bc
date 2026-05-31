package cj2bc.codegen.linker
import cj2bc.bytecode.Bytecode
import cj2bc.bytecode.Instruction
import cj2bc.codegen.state.CodegenState
import cj2bc.codegen.state.LinkerData
import cj2bc.codegen.state.LinkerRelocation
import cj2bc.codegen.state.LinkerLocation

public class Linker {
    public func link(state: CodegenState): Unit {
        let data = state.linkerData
        for (relocation in data.getRelocations()) {
            patch(relocation, state)
        }
        data.clearRelocations()
    }

    private func patch(relocation: LinkerRelocation, state: CodegenState) {
        let index = Int64(relocation.getPosition())
        let instructions = state.bytecode.getInstructionArray()
        let locations = state.linkerData.getLocations()
        instructions[index] = match (relocation.getSize()) {
            case 4 =>
                if (!locations.contains(relocation.getSymbolName())) {
                    throw Exception("Symbol not found: ${relocation.getSymbolName()}")
                }
                let data = locations[relocation.getSymbolName()]
                patch32(instructions[index], data)
            case other =>
                throw Exception("Unsupported relocation size: ${other}")
        }
    }

    private func patchLabel32(instruction: Instruction, data: UInt32): Instruction {
        match (instruction) {
            case Jump(x) => Jump(data)
            case JumpTrue(x) => JumpTrue(data)
            case JumpFalse(x) => JumpFalse(data)
            case Call(x) => Call(data)
            case CallBuiltin(x) => CallBuiltin(data)
            case _ => throw Exception("Label can be only applied to JUMP instructions")
        }
    }

    private func patchGlobal32(instruction: Instruction, data: UInt32) {
        match (instruction) {
            case LoadGlobal(x) => LoadGlobal(data)
            case StoreGlobal(x) => StoreGlobal(data)
            case GetGlobalRef(x) => GetGlobalRef(data)
            case _ => throw Exception("Global variable patches can only be applied to *Global* instructions")
        }
    }

    private func patchFunction32(instruction: Instruction, data: UInt32) {
        match (instruction) {
            case LoadGlobal(x) => FunctionAddress(data)
            case StoreGlobal(x) => throw Exception("Cannot store to function =(")
            case GetGlobalRef(x) => throw Exception("Cannot take address of function =(")
            case _ => throw Exception("Function patches can only be applied to *Global* instructions")
        }
    }

    private func patch32(instruction: Instruction, location: LinkerLocation): Instruction {
        match (location) {
            case LocLabel(x) => patchLabel32(instruction, x)
            case LocGlobalVariable(x) => patchGlobal32(instruction, x)
            case LocGlobalFunction(x) => patchFunction32(instruction, x)
        }
    }

    private func patch64(instruction: Instruction, data: UInt64): Instruction {
        match (instruction) {
            case LoadImm(x) => LoadImm(data)
            case CallCVU64(x) => CallCVU64(data)
            case _ => throw Exception("This instruction cannot be patched with UInt64")
        }
    }
}
