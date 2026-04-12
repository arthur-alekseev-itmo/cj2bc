package cj2bc.codegen

import std.collection.HashMap
import std.collection.ArrayList
import std.convert.Formattable

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

    public func toString() {
        return "Symbol: ${symbolName}, Instruction: ${instructionOffset}, Position: ${instructionPosition}, Size: ${size}"
    }
}

public class LinkerData <: ToString {
    let symbolLocations = HashMap<String, Int32>()
    let relocations = ArrayList<LinkerRelocation>()

    public func addSymbol(name: String, location: Int32): Unit {
        symbolLocations.add(name, location)
    }

    public func addRelocation(name: String, location: Int32, offset: Int32, size: Int32): Unit {
        relocations.add(LinkerRelocation(location, name, size, offset))
    }

    public func toString() {
        let sb = StringBuilder()
        sb.append("RELOCATIONS\n")
        for (relocation in relocations) {
            sb.append("${relocation.toString()}\n")
        }

        sb.append("LOCATIONS\n")
        for (location in symbolLocations.keys()) {
            sb.append("${location}: ${symbolLocations[location]}\n")
        }

        return sb.toString()
    }
}
