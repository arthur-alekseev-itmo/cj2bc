package cj2bc.analysis.typing

import std.collection.ArrayList
import std.collection.HashMap
import cj2bc.simpletree.tree.*
import cj2bc.analysis.typing.types.*
import cj2bc.utils.todo
import cj2bc.analysis.SymbolsScope

private type Scope = SymbolsScope

public class HierarhyCollect {
    var fwid = 0
    private func nextFreeVar() {
        fwid++
        TUnknown(fwid)
    }

    public func collectHierarhy(program: SimpleProgram): SymbolsScope {
        let scope = SymbolsScope()
        collectTypes(program, scope)
        connectTypes(program, scope)
        scope
    }

    private func registerClassDecl(c: ClassDeclData, scope: Scope): Unit {
        let ty = ClassType(c.name)
        let newScope = scope.enterSymbol(ty.name)
        scope.addType(c.name, ty)
        c.innerDecls.map { decl: SimpleDecl => registerDecl(decl, newScope) }
    }

    private func createFnType(f: FuncDeclData, scope: Scope) {
        let parameters = f.parameters.map { p: SimplePattern => resolveParameterType(p, scope) }
        let returnType = nextFreeVar()
        TFunction(parameters, returnType)
    }

    private func registerFuncDecl(f: FuncDeclData, scope: Scope) {
        scope.addSymbol(f.name, ScFuncDecl(f, createFnType(f, scope)))
        let innerScope = scope.enterSymbol(f.name)
        f.body.map { decl: SimpleDecl => registerDecl(decl, innerScope) }
    }

    private func registerInterfaceDecl(i: InterfaceDeclData, scope: Scope) {
        let ty = InterfaceType(i.name)
        let newScope = scope.enterSymbol(ty.name)
        scope.addType(i.name, ty)
        i.innerDecls.map { decl: SimpleDecl => registerDecl(decl, newScope) }
    }

    private func registerVarDecl(v: SimplePattern, b: SimpleExpr, scope: Scope) {
        let name = match (v) {
            case ScVariable(name, _, _) => name
            case _ => throw Exception("Can only work with variables here")
        }
        registerExpr(b, scope)
        scope.addSymbol(name, ScVarDecl(v, b, nextFreeVar()))
    }

    private func registerRunExpr(r: SimpleExpr, scope: Scope) {
        registerExpr(r, scope)
    }

    private func registerExpr(expr: SimpleExpr, scope: Scope): Unit {
        match (expr) {
            case ScConstUnit => ()
            case ScConstInt64(_)  => ()
            case ScConstBool(_)  => ()
            case ScIfThenElse(cond, thenBr, elseBr) =>
                registerExpr(cond, scope)
                registerExpr(thenBr, scope)
                elseBr.map {e => registerExpr(e, scope) }
            case ScBinaryOperator(_, left, right) =>
                registerExpr(left, scope)
                registerExpr(right, scope)
            case ScUnaryOperator(_, expr) =>
                registerExpr(expr, scope)
            case ScCall(callee, args) =>
                registerExpr(callee, scope)
                args.map { a: SimpleExpr => registerExpr(a, scope) }
            case ScBlockExpr(block) =>
                // TODO: New scope?
                block.map { decl: SimpleDecl => registerDecl(decl, scope) }
            case ScReturn(expr) =>
                registerExpr(expr, scope)
            case ScAssign(target, value) =>
                registerExpr(target, scope)
                registerExpr(value, scope)
            case ScVarRef(_) => ()
        }
    }

    private func registerDecl(decl: SimpleDecl, scope: Scope): Unit {
        match (decl) {
            case ScFuncDecl(f, _) => registerFuncDecl(f, scope)
            case ScVarDecl(v, b, _) => registerVarDecl(v, b, scope)
            case ScClassDecl(c) => registerClassDecl(c, scope)
            case ScInterfaceDecl(i) => registerInterfaceDecl(i, scope)
            case ScRunExpr(r) => registerRunExpr(r, scope)
        }
    }

    private func collectTypes(program: SimpleProgram, scope: Scope) {
        program.map { decl: SimpleDecl => registerDecl(decl, scope) } 
    }

    private func resolveSimpleTypeToHierarhical(sty: SimpleType, scope: Scope): HierarhicalType {
        match (sty) {
            case StRefType(ref) => scope.findType(ref.name)
            case _ => todo()
        }
    }

    private func connectClassDecl(classDecl: ClassDeclData, scope: Scope) {
        let klassOption = scope.findType(classDecl.name) as ClassType
        let klass = klassOption.getOrThrow()
        let superTypes = classDecl.superTypes.map { ty => resolveSimpleType(ty, scope) }
        let ifaces = superTypes.filterMap { i => i as InterfaceType }
        let classes = superTypes.filterMap { c => c as ClassType }
        
        ifaces.map { i: InterfaceType => klass.addImplement(i) }
        if (classes.size > 1) {
            throw Exception("More than one superclass")
        }
        classes.map { i: ClassType => klass.setExtend(i) }
        let newScope = scope.enterSymbol(klass.name)
        classDecl.innerDecls.map { d: SimpleDecl => connectDecl(d, newScope) }
    }

    private func connectFuncDecl(_: FuncDeclData, _: Scope) {
        // TODO: Connect types inside
    }

    private func connectInterfaceDecl(interfaceDecl: InterfaceDeclData, scope: Scope) {
        let iface = scope.findType(interfaceDecl.name)
        let superTypes = interfaceDecl.superTypes.map { ty => resolveSimpleType(ty, scope) }
        let ifaces = superTypes.filterMap { i => i as InterfaceType }
        if (ifaces.size != superTypes.size) {
            throw Exception("Interface implements non interface")
        }
        ifaces.map { i: InterfaceType => iface.addImplement(i) }
        let newScope = scope.enterSymbol(iface.name)
        interfaceDecl.innerDecls.map { d: SimpleDecl => connectDecl(d, newScope) }
    }

    private func connectDecl(decl: SimpleDecl, scope: Scope): Unit {
        match (decl) {
            case ScFuncDecl(f, _) => connectFuncDecl(f, scope)
            case ScVarDecl(v, b, _) => ()
            case ScClassDecl(c) => connectClassDecl(c, scope)
            case ScInterfaceDecl(i) => connectInterfaceDecl(i, scope)
            case ScRunExpr(_) => ()
        }
    }

    private func connectTypes(program: SimpleProgram, scope: Scope) {
        program.map { decl: SimpleDecl => connectDecl(decl, scope) }
    }
    
    private func resolveHierarhicalType(ty: HierarhicalType): Type {
        match (ty) {
            case iface: InterfaceType => TInterface(iface)
            case klass: ClassType => TClass(klass)
            case _ => todo()
        }
    }

    private func resolveSimpleType(ty: SimpleType, scope: Scope): Type {
        match (ty) {
            case StPrimitive(StBool) => TBasic(TBool)
            case StPrimitive(StUnit) => TBasic(TUnit)
            case StPrimitive(StInt64) => TBasic(TInt64)
            case StRefType(ref) => resolveHierarhicalType(scope.findType(ref.name)) 
            case StFuncType(f) => TFunction(f.parameters.map { p => resolveSimpleType(p, scope) }, resolveSimpleType(f.result, scope))
        }
    }

    private func resolveParameterType(p: SimplePattern, scope: Scope): Type {
        match (p) {
            case ScVariable(_, Some(anno), _) => resolveSimpleType(anno, scope)
            case _ => throw Exception("Function parameter was noticed without an type annotation. This is a crime")
        }
    }
}