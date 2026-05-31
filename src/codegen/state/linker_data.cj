package cj2bc.codegen.state

import std.collection.HashMap
import std.collection.ArrayList

public struct LinkerRelocation <: ToString {
    let instructionPosition: Int32
    let symbolName: String
    let instructionOffset: Int32
    let size: Int32

    init(position: Int32, symbolName: String, offset: Int32, size: Int32) {
        this.instructionPosition = position
        this.symbolName = symbolName
        this.instructionOffset = offset
        this.size = size
    }

    public func toString(): String {
        return "Symbol: ${symbolName}, Offset: ${instructionOffset}, Position: ${instructionPosition}, Size: ${size}"
    }

    public func getPosition(): Int32 {
        instructionPosition
    }

    public func getOffset(): Int32 {
        instructionOffset
    }

    public func getSize(): Int32 {
        size
    }

    public func getSymbolName(): String {
        symbolName
    }
}


public enum LinkerLocation <: ToString {
    | LocGlobalVariable(UInt32)
    | LocGlobalFunction(UInt32)
    | LocLabel(UInt32)

    public func toString(): String {
        match (this) {
            case LocGlobalVariable(x) => "LocGlobalVariable ${x}"
            case LocGlobalFunction(x) => "LocGlobalFunction ${x}"
            case LocLabel(x) => "LocLabel ${x}"
        }
    }
}

public class LinkerData <: ToString {
    let symbolLocations = HashMap<String, LinkerLocation>()
    let relocations = ArrayList<LinkerRelocation>()

    public func addSymbol(name: String, location: LinkerLocation): Unit {
        symbolLocations.add(name, location)
    }

    public func addRelocation(name: String, location: Int32, offset: Int32, size: Int32): Unit {
        relocations.add(LinkerRelocation(location, name, size, offset))
    }

    public func getRelocations(): ArrayList<LinkerRelocation> {
        relocations
    }

    public func clearRelocations(): Unit {
        relocations.clear()
    }

    public func getLocations(): HashMap<String, LinkerLocation> {
        symbolLocations
    }

    public func toString(): String {
        let sb = StringBuilder()
        sb.append("RELOCATIONS\n")
        for (relocation in relocations) {
            sb.append("${relocation.toString()}\n")
        }

        sb.append("LOCATIONS\n")
        for (location in symbolLocations.keys()) {
            let string: String = "${location}: ${symbolLocations[location]}\n"
            sb.append(string)
        }

        return sb.toString()
    }
}
