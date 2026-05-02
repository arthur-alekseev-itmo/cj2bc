package cj2bc.simpletree.tree

import std.collection.ArrayList

public enum SimplePrimitiveType {
    | StBool
    | StUnit
    | StUInt64
}

public class SimpleRefType {
    let name: String
    let arguments: ArrayList<SimpleType>

    public init(name: String, arguments: ArrayList<SimpleType>) {
        this.arguments = arguments
        this.name = name
    }
}

public class SimpleFuncType {
    let parameters: ArrayList<SimpleType>
    let result: SimpleType

    public init(parameters: ArrayList<SimpleType>, result: SimpleType) {
        this.parameters = parameters
        this.result = result
    }
}

public enum SimpleType {
    | StPrimitive(SimplePrimitiveType)
    | StRefType(SimpleRefType)
    | StFuncType(SimpleFuncType)
}