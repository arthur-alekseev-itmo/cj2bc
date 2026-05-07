package cj2bc.simpletree.parser

import cj2bc.analysis.typing.types.*
import cj2bc.simpletree.tree.*
import std.ast.*
import cj2bc.utils.todo
import std.collection.ArrayList

public class SimpleDeclParser {
    
    private static let CLASS_TYPE: Type = TClass(ClassType("Class"))

    private static func translateFuncDecl(funcDecl: FuncDecl): TypedDecl {
        let parameters = funcDecl.funcParams.map { param: FuncParam =>
            // TODO: More stuff, for instance types, annotations etc
            ScVariable(param.identifier.value, SimpleTypeParser.translateType(param.paramType))
        }
        let body = SimpleParser.translateBlock(funcDecl.block)
        let funcName = funcDecl.identifier.value
        let modifiers = funcDecl.modifiers
        let simpleDecl = ScFuncDecl(FuncDeclData(funcName, parameters, body, modifiers, TNothing))
        TypedDecl(simpleDecl, TUnknown)
    }

    private static func translateMainDecl(mainDecl: MainDecl) {
        let funcDecl = FuncDecl()
        funcDecl.identifier = mainDecl.identifier
        funcDecl.funcParams = mainDecl.funcParams
        funcDecl.block = mainDecl.block
        return translateFuncDecl(funcDecl)
    }

    public static func translatePattern(pattern: Pattern): SimplePattern {
        match (pattern) {
            case constPattern: ConstPattern => todo()
            case wildcardPattern: WildcardPattern => todo()
            case varPattern: VarPattern => ScVariable(varPattern.identifier.value, None)
            case varOrEnumPattern: VarOrEnumPattern => todo()
            case exceptTypePattern: ExceptTypePattern => todo()
            case commandTypePattern: CommandTypePattern => todo()
            case typePattern: TypePattern => todo()
            case enumPattern: EnumPattern => todo()
            case tuplePattern: TuplePattern => todo()
            case _ => throw Exception("Unknown Pattern subtype")
        }
    }

    private static func translateVarDecl(varDecl: VarDecl): TypedDecl {
        // TODO: I dunno when can I use pattern, and when I can use identifier
        // let pattern = translatePattern(varDecl.pattern)
        let pattern = ScVariable(varDecl.identifier.value, None)
        let expr = SimpleExprParser.translateExpr(varDecl.expr)
        let decl = ScVarDecl(pattern, expr)
        TypedDecl(decl, TUnknown)
    }

    private static func translateClassDecl(classDecl: ClassDecl) {
        let name = classDecl.identifier.value
        let superTypes = classDecl.superTypes.map(SimpleTypeParser.translateType)
        let innerDecls = classDecl.body.decls.map(translateDecl)
        let decl = ScClassDecl(ClassDeclData(name, superTypes, innerDecls))
        TypedDecl(decl, CLASS_TYPE)
    }
    
    private static func translateInterfaceDecl(interfaceDecl: InterfaceDecl) {
        let name = interfaceDecl.identifier.value
        let superTypes = interfaceDecl.superTypes.map(SimpleTypeParser.translateType)
        let innerDecls = interfaceDecl.body.decls.map(translateDecl)
        let decl = ScInterfaceDecl(InterfaceDeclData(name, superTypes, innerDecls))
        TypedDecl(decl, CLASS_TYPE)
    }

    public static func translateDecl(decl: Decl): TypedDecl {
        match (decl) {
            case classDecl: ClassDecl => translateClassDecl(classDecl)
            case structDecl: StructDecl => todo()
            case interfaceDecl: InterfaceDecl => translateInterfaceDecl(interfaceDecl)
            case enumDecl: EnumDecl => todo()
            case extendDecl: ExtendDecl => todo()
            case funcDecl: FuncDecl => translateFuncDecl(funcDecl)
            case mainDecl: MainDecl => translateMainDecl(mainDecl)
            case macroDecl: MacroDecl => todo()
            case primaryCtorDecl: PrimaryCtorDecl => todo()
            case varDecl: VarDecl => translateVarDecl(varDecl)
            case funcParamDecl: FuncParam => todo()
            case propDecl: PropDecl => todo()
            case typeAliasDecl: TypeAliasDecl => todo()
            case macroExpandDecl: MacroExpandDecl => todo()
            case _ => throw Exception("Unknown Decl subtype")
        }
    }
}