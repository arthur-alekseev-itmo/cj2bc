package cj2bc.codegen

import std.collection.HashMap
import std.collection.ArrayList

public struct LinkerRelocation {
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
}

public class LinkerData {
    let symbolLocations = HashMap<String, Int32>()
    let relocations = ArrayList<LinkerRelocation>()

    public func addSymbol(name: String, location: Int32) {
        symbolLocations.add(name, location)
    }

    public func addRelocation(name: String, location: Int32, offset: Int32, size: Int32) {
        relocations.add(LinkerRelocation(location, name, size, offset))
    }
}
