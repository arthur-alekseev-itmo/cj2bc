package cj2bc.codegen

import std.collection.HashMap

public enum Variable {
    | LocalVariable(UInt32)
    | ClosureVariable(UInt32)
    | GlobalVariable(UInt32)
}

public class LocalsContextFrame {
    private let variables = HashMap<String, UInt32>()
    private let parent: ?LocalsContextFrame

    init(parent: LocalsContextFrame) {
        this.parent = Some(parent)
    }

    init() {
        this.parent = None
    }

    public func addVariable(name: String): Variable {
        let index = UInt32(variables.size)
        variables.add(name, index)
        LocalVariable(index)
    }

    public func getVariable(name: String): ?Variable {
        func retrieveFromGlobal() {
            if (variables.contains(name)) {
                return Some(GlobalVariable(variables[name]))
            }
            None<Variable>
        }

        func retrieveFromLocal(parent: LocalsContextFrame) {
            if (variables.contains(name)) {
                return LocalVariable(variables[name])
            }
            match (parent.getVariable(name)) {
                case Some(GlobalVariable(v)) => Some(GlobalVariable(v))
                case Some(LocalVariable(v)) => Some(ClosureVariable(v))
                case Some(ClosureVariable(v)) => Some(ClosureVariable(v))
                case None => None<Variable>
            }
        }

        match (parent) {
            case None => retrieveFromGlobal()
            case Some(parent) => retrieveFromLocal(parent)
        }
    }

    public func clear(): Unit {
        variables.clear()
    }

    public func getParent() {
        parent
    }

    public func getVariableIndex() {

    }
}

