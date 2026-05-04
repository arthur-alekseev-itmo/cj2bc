package cj2bc.analysis.typing.types

import std.collection.ArrayList
import std.collection.HashMap
import std.ast.Modifier

public enum BasicType {
    | TInt64 | TBool | TUnit
}

open public class FunctionInfo {
    let name: String
    let ty: Type

    public init(name: String, ty: Type) {
        this.name = name
        this.ty = ty
    }
}

public class MethodInfo <: FunctionInfo {
    private let modifiers: ArrayList<Modifier>
    
    public init(name: String, ty: Type, modifiers: ArrayList<Modifier>) {
        super(name, ty)
        this.modifiers = modifiers
    }
}

open public class NamedType {
    public let name: String

    public init(name: String) {
        this.name = name
    }
}

open public class HierarhicalType <: NamedType   {
    private let implements: ArrayList<InterfaceType>
    private let methods: HashMap<String, MethodInfo>

    public init(name: String) {
        super(name)
        this.implements = ArrayList()
        this.methods = HashMap()
    }

    public func addImplement(iface: InterfaceType): Unit {
        implements.add(iface)
    }

    public func addMethod(method: MethodInfo): Unit {
        methods.add(method.name, method)
    }    
}

public class InterfaceType <: HierarhicalType {
    public init(name: String) {
        super(name)
    }
}

public class ClassType <: HierarhicalType {
    private var extends: ?ClassType
    
    public init(name: String) {
        super(name)
        this.extends = None
    }

    public func setExtend(klass: ClassType): Unit {
        if (extends.isSome()) {
            throw Exception("Superclass is already set")
        }
        extends = klass
    }
}

public enum Type {
    | TUnknown(Int64)
    | TGeneric(String)
    | TAny
    | TNothing
    | TBasic(BasicType)
    | TFunction(ArrayList<Type>, Type)
    | TClass(ClassType)
    | TInterface(InterfaceType)
}
