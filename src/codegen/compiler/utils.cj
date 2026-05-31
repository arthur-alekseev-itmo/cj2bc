package cj2bc.codegen.compiler

import cj2bc.codegen.state.CodegenState
import cj2bc.codegen.state.LinkerLocation

public class Utils {
    private static var branchIndexCounter = 0;
    public static func getBranchNextIndex(): Int64 {
        branchIndexCounter++
        branchIndexCounter
    }

    public static func createFunctionHere(name: String, state: CodegenState): UInt32 {
        let idx = UInt32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addSymbol(name, LocGlobalFunction(idx))
        return idx
    }

    public static func createLabelHere(name: String, state: CodegenState): Unit {
        let idx = UInt32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addSymbol(name, LocLabel(idx))
    }

    public static func createGlobalHere(name: String, state: CodegenState): Unit {
        let idx = UInt32(state.bytecode.getCurrentInstructionIndex())
        state.linkerData.addSymbol(name, LocGlobalVariable(idx))
    }

    public static func createRelocationHere(name: String, size: Int32, offset: Int32, state: CodegenState): Unit {
        let idx = Int32(state.bytecode.getCurrentInstructionIndex() - 1)
        state.linkerData.addRelocation(name, idx, size, offset)
    }

    public static func unableAsRef(): Nothing {
        throw Exception("Unable to use this expression as ref")
    }
}