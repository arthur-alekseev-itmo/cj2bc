package cj2bc.semantic.collect

import std.collection.ArrayList
import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.utils.todo
import cj2bc.common.ScopeOrigin
import cj2bc.common.SymbolsScope
import cj2bc.ast.tree.AstUtils

public class CollectSignatures {

    public static func collect(program: CjProgram, scope: SymbolsScope): SymbolsScope {
        program.map { d => collectDecl(d, scope) }
        scope
    }

    private static func collectExpr(expr: TypedExpr, scope: SymbolsScope): Unit {
        let fExpr = { e => collectExpr(e, scope) }
        let fDecl = { d => collectDecl(d, scope) }
        AstUtils.iterExpr(expr, fExpr, fDecl)
    }

    private static func collectDecl(decl: TypedDecl, scope: SymbolsScope): Unit {
        match (decl.decl) { 
            case ScFuncDecl(f) => collectFunDecl(decl, f, scope)
            case ScBuiltin(_) => ()
            case ScVarDecl(v) => collectVarDecl(decl, v, scope)
            case ScRunExpr(expr) => collectExpr(expr, scope)
            case ScClassDecl(klass) => collectClassDecl(klass, scope)
            case ScInterfaceDecl(iface) => collectInterfaceDecl(iface, scope)
        }
    }

    private static func collectInterfaceDecl(iface: InterfaceDeclData, scope: SymbolsScope): Unit {
        let innerScope = scope.enterSymbol(iface.name)
        iface.innerDecls.map { d: TypedDecl => collectDecl(d, innerScope)}
    }

    private static func collectClassDecl(klass: ClassDeclData, scope: SymbolsScope): Unit {
        let innerScope = scope.enterSymbol(klass.name)
        klass.innerDecls.map { d: TypedDecl => collectDecl(d, innerScope) }
    }

    private static func collectFunDecl(e: TypedDecl, f: FuncDeclData, scope: SymbolsScope) {
        let functionName = match(f.name) {
            case "init" => "()"
            case other => other
        }
        e.ty = createFnType(f, TUnknown, scope)
        scope.addSymbol(functionName, e)
        f.parameters.map { p: CjPattern => addParameterWithType(p, scope) }
        let innerScope = scope.createSymbol(functionName, ScopeOrigin.FunctonScope(f))
        f.body.map { decl: TypedDecl => collectDecl(decl, innerScope) }
    }

    private static func addParameterWithType(p: CjPattern, scope: SymbolsScope) {
        match (p) {
            case ScVariable(name, Some(annotation)) =>
                let paramType = CollectTypes.resolveCjType(annotation, scope)
                let fictionalDecl = TypedDecl(ScVarDecl(CjVarDecl(p, None, ArrayList())), paramType)
                scope.addSymbol(name, fictionalDecl)
            case _ => throw Exception("Bad function parameter")
        }
    }

    private static func createFnType(f: FuncDeclData, returnType: Type, scope: SymbolsScope) {
        let parameters = f.parameters.map { p: CjPattern => resolveParameterType(p, scope) }
        TFunction(parameters, returnType)
    }

    private static func collectVarDecl(e: TypedDecl, v: CjVarDecl, scope: SymbolsScope) {
        let name = match (v.pattern) {
            case ScVariable(name, _) => name
        }
        v.value.map { v => collectExpr(v, scope) }
        scope.addSymbol(name, e) 
    }

    private static func resolveParameterType(p: CjPattern, scope: SymbolsScope): Type {
        match (p) {
            case ScVariable(_, Some(anno)) => CollectTypes.resolveCjType(anno, scope)
            case _ => throw Exception("Function parameter was noticed without an type annotation. This is a crime")
        }
    }
}