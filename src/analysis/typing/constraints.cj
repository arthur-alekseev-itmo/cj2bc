package cj2bc.analysis.typing
import cj2bc.analysis.typing.types.*
import std.collection.HashMap
import std.collection.ArrayList

public class TypeConstraint {
    var lowerbound: ArrayList<Type>
    var upperbound: ArrayList<Type>

    public init() {
        this.lowerbound = ArrayList()
        this.upperbound = ArrayList()
    }

    public func addLower(t: Type): Unit {
        this.lowerbound.add(t)
    }

    public func addUpper(t: Type): Unit {
        this.upperbound.add(t)
    }
}

public class TypeConstraints {
    let constraints: HashMap<Int64, TypeConstraint>
    
    public init() {
        this.constraints = HashMap()
    }

    public func getConstraint(id: Int64): TypeConstraint {
        match (this.constraints.get(id)) {
            case None =>
                let constraint = TypeConstraint()
                this.constraints[id] = constraint
                constraint
            case Some(constraint) =>
                constraint
        }
    }

    public func addLower(id: Int64, t: Type): Unit {
        let constraint = getConstraint(id)
        constraint.addLower(t)
    }

    public func addUpper(id: Int64, t: Type): Unit {
        let constraint = getConstraint(id)
        constraint.addUpper(t)
    }
}

public class JoinAndMeet {
    public static func meet(l: Type, r: Type): Type {
        r // TODO
    }

    public static func join(l: Type, r: Type): Type {
        r // TODO
    }
}

public class PPConstraints {
    public static func constraintToString(target: Int64, c: TypeConstraint): String {
        let lowerboundStrings = c.lowerbound.map(PPType.typeToString).toArray()
        let lowerbounds = String.join(lowerboundStrings, delimiter:", ")
        let upperboundStrings = c.upperbound.map(PPType.typeToString).toArray()
        let upperbounds = String.join(upperboundStrings, delimiter:", ")
        "${lowerbounds} <: ?${target} <: ${upperbounds}"
    }

    public static func constraintsToString(constraints: TypeConstraints): String {
        let strings = constraints.constraints.toArray().map { kvp: (Int64, TypeConstraint) => constraintToString(kvp[0], kvp[1]) }
        String.join(strings.toArray(), delimiter:"\n")
    }
}