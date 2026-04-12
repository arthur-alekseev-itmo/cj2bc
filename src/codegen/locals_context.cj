package cj2bc.codegen

import std.collection.HashMap

public class LocalsContext {
    private let variables = HashMap<String, UInt32>()

    public func addVariable(name: String): UInt32 {
        let index = UInt32(variables.size)
        variables.add(name, index)
        index
    }

    public func getVariable(name: String): UInt32 {
        variables[name]
    }

    public func clear(): Unit {
        variables.clear()
    }
}