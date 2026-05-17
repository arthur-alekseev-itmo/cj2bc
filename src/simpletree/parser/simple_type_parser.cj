package cj2bc.simpletree.parser

import cj2bc.simpletree.tree.*
import std.ast.*
import cj2bc.utils.todo

public class SimpleTypeParser {
    private static func translatePrimitiveType(t: PrimitiveType) {
        let primitive = match (t.keyword.kind) {
            case TokenKind.UINT64 => StUInt64
            case TokenKind.BOOLEAN => StBool
            case TokenKind.UNIT => StUnit
            case _ => todo()
        }
        StPrimitive(primitive)
    }

    private static func translateRefType(t: RefType) {
        let name = t.identifier.value
        let arguments = t.typeArguments.map(translateType)
        let ref = SimpleRefType(name, arguments)
        StRefType(ref)
    }

    private static func translateParenType(t: ParenType) {
        t.parenthesizedType |> translateType
    }

    private static func translateFuncType(t: FuncType) {
        let parameters = t.types.map(translateType)
        let returnType = t.returnType |> translateType
        let funcType = SimpleFuncType(parameters, returnType)
        StFuncType(funcType)
    }

    public static func translateType(typeNode: TypeNode): SimpleType {
        match (typeNode) {
            case primitive: PrimitiveType => translatePrimitiveType(primitive)
            case ref: RefType => translateRefType(ref)
            case qualified: QualifiedType => todo()
            case paren: ParenType => translateParenType(paren)
            case tuple: TupleType => todo()
            case thisType: ThisType => todo()
            case prefix: PrefixType => todo()
            case funcType: FuncType => translateFuncType(funcType)
            case vArray: VArrayType => todo()
            case _ => todo()
        }
    }
}