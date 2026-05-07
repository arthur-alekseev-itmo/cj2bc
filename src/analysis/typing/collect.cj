package cj2bc.analysis.typing

import std.collection.ArrayList
import cj2bc.simpletree.tree.*
import cj2bc.analysis.typing.types.*
import cj2bc.utils.todo
import cj2bc.analysis.SymbolsScope

private type Scope = SymbolsScope

public class Collect {

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
        c.innerDecls.map { decl: TypedDecl => registerDecl(decl, newScope) }
    }

    private func createFnType(f: FuncDeclData, returnType: Type, scope: Scope) {
        let parameters = f.parameters.map { p: SimplePattern => resolveParameterType(p, scope) }
        TFunction(parameters, returnType)
    }

    private func addParameterWithType(p: SimplePattern, scope: Scope) {
        match (p) {
            case ScVariable(name, Some(annotation)) =>
                let paramType = resolveSimpleType(annotation, scope)
                let fictionalDecl = TypedDecl(ScEmptyVarDecl(p), paramType)
                scope.addSymbol(name, fictionalDecl)
            case _ => throw Exception("Bad function parameter")
        }
    }

    private func registerFuncDecl(e: TypedDecl, f: FuncDeclData, scope: Scope) {
        let functionName = match(f.name) {
            case "init" => scope.name // Name of the class
            case other => other
        }
        e.ty = createFnType(f, TUnknown, scope)
        scope.addSymbol(functionName, e)
        f.parameters.map { p: SimplePattern => addParameterWithType(p, scope) }
        let innerScope = scope.enterSymbol(functionName)
        f.body.map { decl: TypedDecl => registerDecl(decl, innerScope) }
    }

    private func registerInterfaceDecl(i: InterfaceDeclData, scope: Scope) {
        let ty = InterfaceType(i.name)
        let newScope = scope.enterSymbol(ty.name)
        scope.addType(i.name, ty)
        i.innerDecls.map { decl: TypedDecl => registerDecl(decl, newScope) }
    }

    private func registerVarDecl(e: TypedDecl, v: SimplePattern, b: TypedExpr, scope: Scope) {
        let name = match (v) {
            case ScVariable(name, _) => name
        }
        registerExpr(b, scope)
        scope.addSymbol(name, e) 
    }

    private func registerRunExpr(r: TypedExpr, scope: Scope) {
        registerExpr(r, scope)
    }

    private func registerExpr(expr: TypedExpr, scope: Scope): Unit {
        match (expr.expr) {
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
                args.map { a: TypedExpr => registerExpr(a, scope) }
            case ScBlockExpr(block) =>
                // TODO: New scope?
                block.map { decl: TypedDecl => registerDecl(decl, scope) }
            case ScReturn(expr) =>
                registerExpr(expr, scope)
            case ScAssign(target, value) =>
                registerExpr(target, scope)
                registerExpr(value, scope)
            case ScVarRef(_) => ()
            case ScMemberAccess(target, _) =>
                registerExpr(target, scope)
        }
    }

    private func registerDecl(decl: TypedDecl, scope: Scope): Unit {
        match (decl.decl) {
            case ScBuiltin(_) => ()
            case ScFuncDecl(f) => registerFuncDecl(decl, f, scope)
            case ScEmptyVarDecl(v) => todo()
            case ScVarDecl(v, b) => registerVarDecl(decl, v, b, scope)
            case ScClassDecl(c) => registerClassDecl(c, scope)
            case ScInterfaceDecl(i) => registerInterfaceDecl(i, scope)
            case ScRunExpr(r) => registerRunExpr(r, scope)
        }
    }

    private func collectTypes(program: SimpleProgram, scope: Scope) {
        program.map { decl: TypedDecl => registerDecl(decl, scope) } 
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
        classDecl.innerDecls.map { d: TypedDecl => connectDecl(d, newScope) }
    }

    private func connectFuncDecl(_: FuncDeclData, _: Scope) {
        // Nothing to be done
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
        interfaceDecl.innerDecls.map { d: TypedDecl => connectDecl(d, newScope) }
    }

    private func connectDecl(decl: TypedDecl, scope: Scope): Unit {
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

    private func connectTypes(program: SimpleProgram, scope: Scope) {
        program.map { decl: TypedDecl => connectDecl(decl, scope) }
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
            case ScVariable(_, Some(anno)) => resolveSimpleType(anno, scope)
            case _ => throw Exception("Function parameter was noticed without an type annotation. This is a crime")
        }
    }
}
