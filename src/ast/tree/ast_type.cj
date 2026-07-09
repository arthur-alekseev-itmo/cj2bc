package cj2bc.ast.tree

import std.collection.ArrayList

public enum CjPrimitiveType {
    | StBool
    | StUnit
    | StUInt64
}

public class CjRefType {
    public let name: String
    public let arguments: ArrayList<CjType>

    public init(name: String, arguments: ArrayList<CjType>) {
        this.arguments = arguments
        this.name = name
    }
}

public class CjFuncType {
    public let parameters: ArrayList<CjType>
    public let result: CjType

    public init(parameters: ArrayList<CjType>, result: CjType) {
        this.parameters = parameters
        this.result = result
    }
}

public enum CjType {
    | StPrimitive(CjPrimitiveType)
    | StRefType(CjRefType)
    | StFuncType(CjFuncType)
}