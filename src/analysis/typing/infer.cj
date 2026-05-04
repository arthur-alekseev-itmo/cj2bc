package cj2bc.analysis.typing

import cj2bc.simpletree.tree.*
import cj2bc.utils.todo
import std.collection.HashMap
import std.collection.ArrayList
import cj2bc.analysis.typing.types.*
import cj2bc.analysis.SymbolsScope
import cj2bc.simpletree.pp.PpSimpleTree


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

    private let constraints = TypeConstraints()

    // left <: right
    private func constrainLower(l: Type, r: Type) {
        if (let TUnknown(lid) <- l) {
            constraints.addLower(lid, r)
        }

        if (let TUnknown(rid) <- r) {
            constraints.addUpper(rid, l)
        }
    }

    // right <: left
    private func constrainUpper(l: Type, r: Type) {
        if (let TUnknown(lid) <- l) {
            constraints.addUpper(lid, r)
        }

        if (let TUnknown(rid) <- r) {
            constraints.addLower(rid, l)
        }
    }

    private func constrainEq(l: Type, r: Type) {
        constrainLower(l, r)
        constrainUpper(l, r)
    }

    public func infer(program: SimpleProgram, scope: SymbolsScope): TypeConstraints {
        let ctx = InferContext(scope)
        // TODO: Better builtins
        ctx.addSymbol("println", TypedDecl(ScBuiltin("println"), TFunction(ArrayList([TBasic(TInt64)]), TBasic(TUnit))))
        
        program.map { d: TypedDecl => inferDecl(d, ctx) } 
        constraints
    }

    private func inferIfThenElse(e: TypedExpr, cond: TypedExpr, brThen: TypedExpr, brElse: ?TypedExpr, ctx: Ctx) {
        inferExpr(cond, ctx)
        inferExpr(brThen, ctx)
        let brElseType = match (brElse) {
            case None => TBasic(TUnit)
            case Some(t) => t.ty
        }
        constrainUpper(e.ty, brThen.ty)
        constrainUpper(e.ty, brElseType)
        constrainEq(cond.ty, TBasic(TBool))
    }

    private func inferBinop(e: TypedExpr, op: SimpleBinaryOperator, left: TypedExpr, right: TypedExpr, ctx: Ctx) {
        inferExpr(left, ctx)
        inferExpr(right, ctx)
        let leftTy = left.ty
        let rightTy = right.ty
        match(op) {
            case Add | Sub | Mul | Div | Mod =>
                constrainEq(e.ty, rightTy)
                constrainEq(rightTy, leftTy)
            case Eq | Neq | Ge | Le | Gt | Lt =>
                constrainEq(e.ty, TBasic(TBool))
            case And | Or =>
                constrainEq(e.ty, TBasic(TBool))
                constrainEq(leftTy, rightTy)
            case BitAnd | BitOr | BitXor =>
                constrainEq(e.ty, leftTy)
                constrainEq(leftTy, rightTy)
        }
    }

    private func inferUnop(_: SimpleUnaryOperator, expr: TypedExpr, ctx: Ctx) {
        inferExpr(expr, ctx)
        // TODO: All of current binops do not alter the type
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

    private func inferCall(e: TypedExpr, callee: TypedExpr, args: ArrayList<TypedExpr>, ctx: Ctx) {
        inferExpr(callee, ctx)
        args.map { a: TypedExpr => inferExpr(a, ctx) }
        match (callee.ty) {
            // TODO: Тут явно что-то не так, надо видимо как-то смотреть что это функция
            case TFunction(params, body) =>
                // TODO: Maybe check call types
                // TODO: For real, generics might be needed, oh no...
                constrainEq(e.ty, body)
            case _ => throw Exception("Applying non function???? ${PpSimpleTree.exprToString(callee)}: ${PPType.typeToString(callee.ty)}")
        }
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
        constrainEq(expr.ty, ty)
    }

    private func inferReturn(expr: TypedExpr, value: TypedExpr, ctx: Ctx) {
        expr.ty = TNothing        
        inferExpr(value, ctx)
        ctx.addReturnedType(value.ty)
    }

    private func inferAssign(expr: TypedExpr, target: TypedExpr, value: TypedExpr, ctx: Ctx) {
        inferExpr(target, ctx)
        inferExpr(value, ctx)
        constrainLower(target.ty, value.ty)  // !!!!
        expr.ty = TBasic(TUnit)
    }

    private func inferVarRef(expr: TypedExpr, name: String, ctx: Ctx) {
        let decl = ctx.findSymbol(name)
        expr.ty = decl.ty
    }

    private func inferExpr(expr: TypedExpr, ctx: Ctx): Unit {
        return match (expr.expr) {
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

    private func inferParameter(param: SimplePattern, ctx: Ctx) {
        // We know that type must always be provided for parameter
        match (param) {
            case ScVariable(v, Some(annotation)) =>
                let ty = resolveSimpleType(annotation, ctx)
                (ty, ScVariable(v, Some(annotation)))
            case ScVariable(v, None) => throw Exception("Function parameter must be annotated")
        } 
    }

    private func inferFuncDecl(_: TypedDecl, f: FuncDeclData, ctx: Ctx) {
        let newCtx = ctx.enterSymbol(f.name)
        // f.parameters.map { p: SimplePattern => inferParameter(p, ctx) }
        inferBlock(f.body, newCtx)
        newCtx.returnedTypes.map { t: Type => constrainUpper(f.resultType, t) }
    }

    private func inferVarDecl(decl: TypedDecl, expr: TypedExpr, ctx: Ctx) {
        inferExpr(expr, ctx)
        decl.ty = expr.ty
    }

    private func inferClassDecl(_: ClassDeclData, _: Ctx) {
        todo()
    }

    private func inferInterfaceDecl(_: InterfaceDeclData, _: Ctx) {
        todo()
    }

    private func inferRunExpr(decl: TypedDecl, expr: TypedExpr, ctx: Ctx) {
        inferExpr(expr, ctx)
        constrainEq(decl.ty, expr.ty)
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
