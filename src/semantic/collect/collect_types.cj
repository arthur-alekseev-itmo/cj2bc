package cj2bc.semantic.collect

import std.collection.ArrayList
import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.utils.todo
import cj2bc.common.ScopeOrigin
import cj2bc.common.SymbolsScope
import cj2bc.ast.tree.AstUtils

private type Scope = SymbolsScope

public class CollectTypes {

    public static func collectHierarhy(program: CjProgram): SymbolsScope {
        let scope = SymbolsScope()
        collectTypes(program, scope)
        connectTypes(program, scope)
        scope
    }

    private static func registerClassDecl(decl: TypedDecl, c: ClassDeclData, scope: Scope): Unit {
        let ty = ClassType(c.name)
        c.ty = Some(ty)
        let newScope = scope.createSymbol(ty.name, ScopeOrigin.ClassScope(c))
        scope.addType(c.name, ty)
        scope.addSymbol(c.name, decl)
        c.innerDecls.map { decl: TypedDecl => registerDecl(decl, newScope) }
    }

    private static func registerInterfaceDecl(decl: TypedDecl, i: InterfaceDeclData, scope: Scope) {
        let ty = InterfaceType(i.name)
        i.ty = Some(ty)
        let newScope = scope.createSymbol(ty.name, ScopeOrigin.InterfaceScope(i))
        scope.addType(i.name, ty)
        scope.addSymbol(i.name, decl)
        i.innerDecls.map { decl: TypedDecl => registerDecl(decl, newScope) }
    }

    private static func registerRunExpr(r: TypedExpr, scope: Scope) {
        registerExpr(r, scope)
    }

    private static func registerExpr(expr: TypedExpr, scope: Scope): Unit {
        let fExpr = { e => registerExpr(e, scope) }
        let fDecl = { d => registerDecl(d, scope) } 
        AstUtils.iterExpr(expr, fExpr, fDecl)
    }

    private static func registerFunction(f: FuncDeclData, scope: Scope): Unit {
        let innerScope = scope.createSymbol(f.name, ScopeOrigin.FunctonScope(f))
        f.body.map { e => registerDecl(e, innerScope) }
    }

    private static func registerDecl(decl: TypedDecl, scope: Scope): Unit {
        match (decl.decl) {
            case ScBuiltin(_) => ()
            case ScFuncDecl(f) => registerFunction(f, scope)
            case ScEmptyVarDecl(v) => todo()
            case ScVarDecl(v, b) => ()
            case ScClassDecl(c) => registerClassDecl(decl, c, scope)
            case ScInterfaceDecl(i) => registerInterfaceDecl(decl, i, scope)
            case ScRunExpr(r) => registerRunExpr(r, scope)
        }
    }

    private static func collectTypes(program: CjProgram, scope: Scope) {
        program.map { decl: TypedDecl => registerDecl(decl, scope) } 
    }

    private static func connectClassDecl(classDecl: ClassDeclData, scope: Scope) {
        let klassOption = scope.findType(classDecl.name) as ClassType
        let klass = klassOption.getOrThrow()
        let superTypes = classDecl.superTypes.map { ty => resolveCjType(ty, scope) }
        let ifaces = superTypes.filterMap { i => i as InterfaceType }
        let classes = superTypes.filterMap { c => c as ClassType }
        
        ifaces.map { i: InterfaceType => klass.addImplement(i) }
        if (classes.size > 1) {
            throw Exception("More than one superclass")
        }
        classes.map { i: ClassType => klass.setExtend(i) }
        let newScope = scope.enterSymbol(klass.name)
        classDecl.innerDecls.map { d: TypedDecl => connectDecl(d, newScope) }
    }

    private static func connectFuncDecl(_: FuncDeclData, _: Scope) {
        // Nothing to be done
    }

    private static func connectInterfaceDecl(interfaceDecl: InterfaceDeclData, scope: Scope) {
        let iface = scope.findType(interfaceDecl.name)
        let superTypes = interfaceDecl.superTypes.map { ty => resolveCjType(ty, scope) }
        let ifaces = superTypes.filterMap { i => i as InterfaceType }
        if (ifaces.size != superTypes.size) {
            throw Exception("Interface implements non interface")
        }
        ifaces.map { i: InterfaceType => iface.addImplement(i) }
        let newScope = scope.enterSymbol(iface.name)
        interfaceDecl.innerDecls.map { d: TypedDecl => connectDecl(d, newScope) }
    }

    private static func connectDecl(decl: TypedDecl, scope: Scope): Unit {
        match (decl.decl) {
            case ScBuiltin(_) => ()
            case ScFuncDecl(f) => connectFuncDecl(f, scope)
            case ScEmptyVarDecl(v) => ()
            case ScVarDecl(v, b) => ()
            case ScClassDecl(c) => connectClassDecl(c, scope)
            case ScInterfaceDecl(i) => connectInterfaceDecl(i, scope)
            case ScRunExpr(_) => ()
        }
    }

    private static func connectTypes(program: CjProgram, scope: Scope) {
        program.map { decl: TypedDecl => connectDecl(decl, scope) }
    }
    
    private static func resolveHierarhicalType(ty: HierarhicalType): Type {
        match (ty) {
            case iface: InterfaceType => TInterface(iface)
            case klass: ClassType => TClass(klass)
            case _ => todo()
        }
    }

    public static func resolveCjType(ty: CjType, scope: Scope): Type {
        match (ty) {
            case StPrimitive(StBool) => TBasic(TBool)
            case StPrimitive(StUnit) => TBasic(TUnit)
            case StPrimitive(StInt64) => TBasic(TInt64)
            case StRefType(ref) => resolveHierarhicalType(scope.findType(ref.name)) 
            case StFuncType(f) => TFunction(f.parameters.map { p => resolveCjType(p, scope) }, resolveCjType(f.result, scope))
        }
    }
}
