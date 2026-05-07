package cj2bc.analysis.typing

import cj2bc.simpletree.tree.*
import cj2bc.utils.todo
import std.collection.HashMap
import std.collection.ArrayList
import cj2bc.analysis.typing.types.*
import cj2bc.analysis.*

private class InferContext {
    let parent: ?InferContext
    let returnedTypes: ArrayList<Type>
    let scope: SymbolsScope

    public init(scope: SymbolsScope) {
        this.parent = None
        this.returnedTypes = ArrayList()
        this.scope = scope
    }

    public func enterSymbol(name: String): InferContext {
        let childScope = this.scope.children[name]
        InferContext(childScope, this)
    }

    public init(scope: SymbolsScope, parent: InferContext) {
        this.parent = parent
        this.returnedTypes = ArrayList()
        this.scope = scope
    }

    public func addReturnedType(ty: Type): Unit {
        returnedTypes.add(ty)
    }

    public func findSymbol(name: String): TypedDecl {
        scope.findSymbol(name)
    }

    public func findType(name: String): HierarhicalType {
        scope.findType(name)
    }

    public func addSymbol(name: String, symbol: TypedDecl): Unit {
        scope.addSymbol(name, symbol)
    }
}

private type Ctx = InferContext

public class Inference {

    public func infer(program: SimpleProgram, scope: SymbolsScope): Unit {
        let ctx = InferContext(scope)
        // TODO: Better builtins
        ctx.addSymbol("println", TypedDecl(ScBuiltin("println"), TFunction(ArrayList([TBasic(TInt64)]), TBasic(TUnit))))
        
        program.map { d: TypedDecl => inferDecl(d, ctx) } 
    }

    private func inferIfThenElse(_: TypedExpr, cond: TypedExpr, _: TypedExpr, _: ?TypedExpr, _: Ctx) {
        cond.ty = TBasic(TBool)
    }

    private func inferBinop(_: TypedExpr, _: SimpleBinaryOperator, left: TypedExpr, right: TypedExpr, ctx: Ctx) {
        inferExpr(left, ctx)
        inferExpr(right, ctx)
    }

    private func inferUnop(_: SimpleUnaryOperator, expr: TypedExpr, ctx: Ctx) {
        inferExpr(expr, ctx)
    } 

    private func unzip<T, U>(pairs: ArrayList<(T, U)>): (ArrayList<T>, ArrayList<U>) {
        let lefts = ArrayList<T>()
        let rights = ArrayList<U>()
        for ((left, right) in pairs) {
            lefts.add(left)
            rights.add(right)
        }
        (lefts, rights)
    }

    private func inferCall(_: TypedExpr, callee: TypedExpr, args: ArrayList<TypedExpr>, ctx: Ctx): Unit {
        inferExpr(callee, ctx)
        args.map { a: TypedExpr => inferExpr(a, ctx) }
        // TODO: maybe something can be assumed if the function has known return type...
    }

    private func inferBlock(block: TypedBlock, ctx: Ctx) {
        let lastDecl = block.last
        let otherDecls = block.take(block.size - 1)
        otherDecls.map { d => inferDecl(d, ctx) }

        match (lastDecl.map { x => x.decl}) {
            case Some(ScRunExpr(e)) =>
                inferExpr(e, ctx)
                e.ty
            case Some(other) =>
                inferDecl(lastDecl.getOrThrow(), ctx) 
                TBasic(TUnit)
            case None =>
                TBasic(TUnit)
        }
    }

    private func inferBlockExpr(expr: TypedExpr, block: TypedBlock, ctx: Ctx) {
        let ty = inferBlock(block, ctx)
        expr.ty = ty
    }

    private func inferReturn(expr: TypedExpr, value: TypedExpr, ctx: Ctx) {
        expr.ty = TNothing        
        // TODO: Do not mark the type as unknown later, to enable optimisations
        // Enable boxing of return value
        value.ty = TUnknown
        inferExpr(value, ctx)
        ctx.addReturnedType(value.ty)
    }

    private func inferAssign(expr: TypedExpr, target: TypedExpr, value: TypedExpr, ctx: Ctx) {
        inferExpr(target, ctx)
        inferExpr(value, ctx)
        expr.ty = TBasic(TUnit)
    }

    private func inferVarRef(expr: TypedExpr, name: String, ctx: Ctx) {
        let decl = ctx.findSymbol(name)
        expr.ty = decl.ty
    }

    private func inferMemberAccess(_: TypedExpr, target: TypedExpr, _: String, ctx: Ctx) {
        inferExpr(target, ctx)
    }

    private func inferExpr(expr: TypedExpr, ctx: Ctx): Unit {
        return match (expr.expr) {
            case ScMemberAccess(target, member) => inferMemberAccess(expr, target, member, ctx)
            case ScConstUnit => expr.ty = TBasic(TUnit)
            case ScConstInt64(_) => expr.ty = TBasic(TInt64)
            case ScConstBool(_) => expr.ty = TBasic(TBool)
            case ScIfThenElse(cond, brThen, brElse) => inferIfThenElse(expr, cond, brThen, brElse, ctx)
            case ScBinaryOperator(op, left, right) => inferBinop(expr, op, left, right, ctx)
            case ScUnaryOperator(op, expr) => inferUnop(op, expr, ctx)
            case ScCall(callee, args) => inferCall(expr, callee, args, ctx)
            case ScBlockExpr(block) => inferBlockExpr(expr, block, ctx)
            case ScReturn(value) => inferReturn(expr, value, ctx)
            case ScAssign(target, value) => inferAssign(expr, target, value, ctx)
            case ScVarRef(v) => inferVarRef(expr, v, ctx)
        }
    }

    private func resolveHierarhicalType(ty: HierarhicalType): Type {
        match (ty) {
            case iface: InterfaceType => TInterface(iface)
            case klass: ClassType => TClass(klass)
            case _ => todo()
        }
    }

    private func resolveSimpleType(ty: SimpleType, ctx: Ctx): Type {
        match (ty) {
            case StPrimitive(StBool) => TBasic(TBool)
            case StPrimitive(StUnit) => TBasic(TUnit)
            case StPrimitive(StInt64) => TBasic(TInt64)
            case StRefType(ref) => resolveHierarhicalType(ctx.findType(ref.name)) 
            case StFuncType(f) => TFunction(f.parameters.map { p => resolveSimpleType(p, ctx) }, resolveSimpleType(f.result, ctx))
        }
    }

    private func inferFuncDecl(_: TypedDecl, f: FuncDeclData, ctx: Ctx) {
        let functionName = match (f.name) {
            case "init" => ctx.scope.name
            case other => other
        }
        let newCtx = ctx.enterSymbol(functionName)
        inferBlock(f.body, newCtx)
        // TODO: Something cool here
        // For example if all are known as Ints, make the result Int
        // If not, make all return exprs unknwon to box them
    }

    private func inferVarDecl(decl: TypedDecl, expr: TypedExpr, ctx: Ctx) {
        inferExpr(expr, ctx)
        decl.ty = expr.ty
    }

    private func inferClassDecl(decl: ClassDeclData, ctx: Ctx) {
        let newCtx = ctx.enterSymbol(decl.name)
        decl.innerDecls.map { d: TypedDecl => inferDecl(d, newCtx) }    
    }

    private func inferInterfaceDecl(_: InterfaceDeclData, _: Ctx) {
        todo()
    }

    private func inferRunExpr(decl: TypedDecl, expr: TypedExpr, ctx: Ctx) {
        inferExpr(expr, ctx)
        decl.ty = TBasic(TUnit)
    }

    private func inferDecl(decl: TypedDecl, ctx: Ctx): Unit {
        match (decl.decl) {
            case ScFuncDecl(f) => inferFuncDecl(decl, f, ctx)
            case ScBuiltin(_) => ()
            case ScEmptyVarDecl(_) => todo()
            case ScVarDecl(v, b) => inferVarDecl(decl, b, ctx)
            case ScClassDecl(c) => inferClassDecl(c, ctx)
            case ScInterfaceDecl(i) => inferInterfaceDecl(i, ctx)
            case ScRunExpr(e) => inferRunExpr(decl, e, ctx) 
       }
    }
}
