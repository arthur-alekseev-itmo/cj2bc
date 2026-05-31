package cj2bc.prettyprint

import cj2bc.ast.types.*

public class PPType {
    public static func basicTypeToString(b: BasicType): String {
        match (b) {
            case TUnit => "Unit"
            case TBool => "Bool"
            case TInt64 => "Int64"
        }
    }

    public static func typeToString(t: Type): String {
        match (t) {
            case TUnknown => "(?)"
            case TAny => "Any"
            case TNothing => "Nothing" 
            case TBasic(b) => basicTypeToString(b)
            case TFunction(p, r) => 
                let result = typeToString(r)
                let paramStrings = p.map(typeToString).toArray()
                let params = String.join(paramStrings, delimiter:", ")
                "(${params}) -> ${result}"
            case TClass(c) => c.name
            case TInterface(c) => c.name
        }
    }
}