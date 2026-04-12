package cj2bc.codegen

import std.collection.HashMap

public class LocalsContext {
    private let variables = HashMap<String, Int32>()

    public func addVariable(name: String): Int32 {
        let index = Int32(variables.size)
        variables.add(name, index)
        index
    }

    public func getVariable(name: String): Int32 {
        variables[name]
    }

    public func clear(): Unit {
        variables.clear()
    }
}