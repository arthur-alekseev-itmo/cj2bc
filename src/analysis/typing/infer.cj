package cj2bc.analysis.typing

import cj2bc.simpletree.tree.*
import cj2bc.utils.todo
import std.collection.HashMap
import std.collection.ArrayList
import cj2bc.analysis.typing.types.*

private class InferContext {
    let variables: HashMap<String, Type>
    let parent: ?InferContext
    let returnedTypes: ArrayList<Type>

    public init() {
        this.variables = HashMap()
        this.parent = None
        this.returnedTypes = ArrayList()
    }

    public init(parent: InferContext) {
        this.parent = parent
        this.variables = HashMap()
        this.returnedTypes = ArrayList()
    }

    public func addReturnedType(ty: Type): Unit {
        returnedTypes.add(ty)
    }

    public func addValue(name: String, ty: Type): Unit {
        variables.add(name, ty)
    }

    public func lookup(name: String): Type {
        match ((variables.get(name), parent)) {
            case (Some(x), _) => x
            case (None, Some(p)) => p.lookup(name)
            case (None, None) => throw Exception("The variable with name ${name} was not found")
        }
    }
}

private type Ctx = InferContext

public class Inference {
    let hierarhy: ClassHierarhy

    public init(hierarhy: ClassHierarhy) {
        this.hierarhy = hierarhy
    }

    public func infer(program: SimpleProgram): SimpleProgram {
        let ctx = InferContext()
        // TODO: Better builtins
        ctx.addValue("println", TFunction(ArrayList([TBasic(TInt64)]), TBasic(TUnit)))
        program.map { d: SimpleDecl => inferDecl(d, ctx) } 
    }

    private func upperbound(x: Type, _: Type): Type {
        print("WARNING! GLB IS NOT DONE!")
        x
    }

    private func inferIfThenElse(cond: SimpleExpr, brThen: SimpleExpr, brElse: ?SimpleExpr, ctx: Ctx) {
        let (condType, iCond) = inferExpr(cond, ctx)
        match (condType) {
            case TBasic(TBool) => ()
            case _ => throw Exception("The condition type must be bool")
        }
        let (brThenType, iBrThen) = inferExpr(brThen, ctx)
        let (brElseType, iBrElse) = match (brElse.map {e => inferExpr(e, ctx) }) {
            case None => (TBasic(TUnit), None<SimpleExpr>)
            case Some((x, y)) => (x, Some(y)) 
        }
        let wholeExprType = upperbound(brThenType, brElseType)
        (wholeExprType, ScIfThenElse(iCond, iBrThen, iBrElse))
    }

    private func assertEqAndRet(left: Type, _: Type) {
        // TODO: Check equality
        left
    }

    private func inferBinop(op: SimpleBinaryOperator, left: SimpleExpr, right: SimpleExpr, ctx: Ctx) {
        let (leftTy, iLeft) = inferExpr(left, ctx)
        let (rightTy, iRight) = inferExpr(right, ctx)
        let wholeExprTy = match(op) {
            case Add | Sub | Mul | Div | Mod => assertEqAndRet(leftTy, rightTy)
            case Eq | Neq | Ge | Le | Gt | Lt => TBasic(TBool)
            case And | Or => assertEqAndRet(leftTy, rightTy)
            case BitAnd | BitOr | BitXor => assertEqAndRet(leftTy, rightTy)
        }
        (wholeExprTy, ScBinaryOperator(op, iLeft, iRight))
    }

    private func inferUnop(_: SimpleUnaryOperator, expr: SimpleExpr, ctx: Ctx) {
        let (exprTy, iExpr) = inferExpr(expr, ctx)
        // TODO: All of current binops do not alter the type
        (exprTy, iExpr)
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

    private func inferCall(callee: SimpleExpr, args: ArrayList<SimpleExpr>, ctx: Ctx) {
        let (calleeTy, iCallee) = inferExpr(callee, ctx)
        let (argTys, iArgs) = args.map { a: SimpleExpr => inferExpr(a, ctx) } |> unzip
        match (calleeTy) {
            case TFunction(params, body) => 
                // TODO: Maybe check call types
                // TODO: For real, generics might be needed, oh no...
                (body, ScCall(iCallee, iArgs))
            case _ => throw Exception("Applying non function")
        }
    }

    private func inferBlock(block: SimpleBlock, ctx: Ctx) {
        let lastDecl = block.last
        let otherDecls = block.take(block.size - 1)
        let iOther = otherDecls.map { d => inferDecl(d, ctx) }

        match (lastDecl) {
            case Some(ScRunExpr(e)) =>
                let (ty, iExpr) = inferExpr(e, ctx)
                let iLastDecl = ScRunExpr(iExpr)
                iOther.add(iLastDecl)
                (ty, iOther)
            case Some(other) =>
                let iLast = inferDecl(other, ctx) 
                iOther.add(iLast)
                (TBasic(TUnit), iOther)
            case None =>
                (TBasic(TUnit), block)
        }
    }

    private func inferBlockExpr(block: SimpleBlock, ctx: Ctx) {
        let (ty, iBlock) = inferBlock(block, ctx)
        (ty, ScBlockExpr(iBlock))
    }

    private func inferReturn(expr: SimpleExpr, ctx: Ctx) {
        let (ty, iExpr) = inferExpr(expr, ctx)
        ctx.addReturnedType(ty)
        (TNothing, ScReturn(iExpr))        
    }

    private func inferAssign(target: SimpleExpr, expr: SimpleExpr, ctx: Ctx) {
        let (targetTy, iTarget) = inferExpr(target, ctx)
        let (exprTy, iExpr) = inferExpr(expr, ctx)
        // TODO: assert is super
        (TBasic(TUnit), ScAssign(iTarget, iExpr))
    }

    private func inferVarRef(v: String, ctx: Ctx) {
        let ty = ctx.lookup(v)
        (ty, ScVarRef(v))
    }

    private func inferExpr(expr: SimpleExpr, ctx: Ctx): (Type, SimpleExpr) {
        return match (expr) {
            case ScConstUnit => (TBasic(TUnit), expr)
            case ScConstInt64(_) => (TBasic(TInt64), expr)
            case ScConstBool(_) => (TBasic(TBool), expr)
            case ScIfThenElse(cond, brThen, brElse) => inferIfThenElse(cond, brThen, brElse, ctx)
            case ScBinaryOperator(op, left, right) => inferBinop(op, left, right, ctx)
            case ScUnaryOperator(op, expr) => inferUnop(op, expr, ctx)
            case ScCall(callee, args) => inferCall(callee, args, ctx)
            case ScBlockExpr(block) => inferBlockExpr(block, ctx)
            case ScReturn(expr) => inferReturn(expr, ctx)
            case ScAssign(target, expr) => inferAssign(target, expr, ctx)
            case ScVarRef(v) => inferVarRef(v, ctx)
        }
    }

    private func resolveHierarhicalType(ty: HierarhicalType): Type {
        match (ty) {
            case iface: InterfaceType => TInterface(iface)
            case klass: ClassType => TClass(klass)
            case _ => todo()
        }
    }

    private func resolveSimpleType(ty: SimpleType): Type {
        match (ty) {
            case StPrimitive(StBool) => TBasic(TBool)
            case StPrimitive(StUnit) => TBasic(TUnit)
            case StPrimitive(StInt64) => TBasic(TInt64)
            case StRefType(ref) => resolveHierarhicalType(hierarhy.findType(ref.name)) 
            case StFuncType(f) => TFunction(f.parameters.map(resolveSimpleType), resolveSimpleType(f.result))
        }
    }

    private func inferParameter(param: SimplePattern, _: Ctx) {
        // We know that type must always be provided for parameter
        match (param) {
            case ScVariable(v, Some(annotation), _) =>
                let ty = resolveSimpleType(annotation)
                (ty, ScVariable(v, Some(annotation), ty))
            case ScVariable(v, None, _) => throw Exception("Function parameter must be annotated")
        } 
    }

    private func addPatternToCtx(p: (Type, SimplePattern), ctx: Ctx) {
        match (p[1]) {
            case ScVariable(v, _, _) => ctx.addValue(v, p[0])
        }
    }

    private func addTypeToPattern(p: SimplePattern, t: Type) {
        match (p) {
            case ScVariable(name, annotation, _) => ScVariable(name, annotation, t)
        }
    }

    private func inferFuncDecl(decl: FuncDeclData, ctx: Ctx) {
        let newCtx = InferContext(ctx)
        let decomposedParams = decl.parameters.map { p => inferParameter(p, ctx) }
        let (paramTypes, typedParams) = unzip(decomposedParams)
        newCtx.addValue(decl.name, TFunction(paramTypes, TNothing)) // For recursion
        decomposedParams.map { p: (Type, SimplePattern) => addPatternToCtx(p, newCtx) }
        let (bodyTy, iBody) = inferBlock(decl.body, newCtx)
        newCtx.addReturnedType(bodyTy)
        let returnType = newCtx.returnedTypes.fold(TNothing, upperbound)
        let iDecl = FuncDeclData(decl.name, typedParams, iBody, decl.modifiers)
        let ty = TFunction(paramTypes, returnType)
        ctx.addValue(decl.name, ty)
        ScFuncDecl(iDecl, ty) 
    }

    private func inferVarDecl(pattern: SimplePattern, expr: SimpleExpr, ctx: Ctx) {
        let (ty, iExpr) = inferExpr(expr, ctx)
        addPatternToCtx((ty, pattern), ctx)
        let iPattern = addTypeToPattern(pattern, ty)
        ScVarDecl(iPattern, iExpr, ty)
    }

    private func inferClassDecl(_: ClassDeclData, _: Ctx) {
        todo()
    }

    private func inferInterfaceDecl(_: InterfaceDeclData, _: Ctx) {
        todo()
    }

    private func inferRunExpr(expr: SimpleExpr, ctx: Ctx) {
        let (_, iExpr) = inferExpr(expr, ctx)
        ScRunExpr(iExpr)
    }

    private func inferDecl(decl: SimpleDecl, ctx: Ctx): SimpleDecl {
        match (decl) {
            case ScFuncDecl(f, _) => inferFuncDecl(f, ctx)
            case ScVarDecl(v, b, _) => inferVarDecl(v, b, ctx)
            case ScClassDecl(c) => inferClassDecl(c, ctx)
            case ScInterfaceDecl(i) => inferInterfaceDecl(i, ctx)
            case ScRunExpr(e) => inferRunExpr(e, ctx) 
       }
    }
}
