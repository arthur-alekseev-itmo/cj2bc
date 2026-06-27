package cj2bc.semantic.transform

import cj2bc.utils.todo

import cj2bc.ast.tree.*
import cj2bc.ast.types.*
import cj2bc.common.SymbolsScope
import std.collection.ArrayList
import std.collection.HashSet

public class ImplicitThisTransforms {

    private static func getPatternNames(pat: CjPattern) {
        match (pat) {
            case ScVariable(name, _) => ArrayList([name])
        }
    }

    private static func isFieldDecl(decl: TypedDecl): ArrayList<String> {
        match (decl.decl) {
            case ScVarDecl(varDecl) => getPatternNames(varDecl.pattern)
            case _ => ArrayList<String>()
        }
    }

    private static func collectFieldDeclarations(klass: ClassDeclData, scope: SymbolsScope): ArrayList<String> {
        let self = klass.innerDecls.flatMap(isFieldDecl)
        
        let superType = match (klass.ty) {
            case None => throw Exception("Class type was none")
            case Some(x) where x is ClassType => (x as ClassType).getOrThrow().getExtend()
            case _ => throw Exception("Class type was not a class")
        }

        let superDecl = superType
            .map { x => scope.getParent().findSymbol(x.name) }
            .map { x => x.decl }

        let other = match (superDecl) {
            case Some(ScClassDecl(x)) =>
                let innerScope = /* TODO: Get scope for any decl */ scope
                collectFieldDeclarations(x, innerScope)
            case Some(_) => throw Exception("Extends was not a class decl")
            case None => ArrayList<String>()
        }

        self.add(all: other)
        return self
    }

    private static func addThisToDecl(decl: TypedDecl, fields: HashSet<String>): TypedDecl {
        match (decl.decl) {
            case ScFuncDecl(f) => todo("func decl")
            case ScBuiltin(_) => decl 
            case ScVarDecl(varDecl) =>
                let newExpr = varDecl.value.map { x => addThisToExpr(x, fields) }
                fields.remove(all: getPatternNames(varDecl.pattern))
                TypedDecl(ScVarDecl(CjVarDecl(varDecl.pattern, newExpr, varDecl.modifiers)), decl.ty)
            case ScRunExpr(expr) =>
                TypedDecl(ScRunExpr(addThisToExpr(expr, fields)), decl.ty)
            case ScClassDecl(clazz) => todo("inner class")
            case ScInterfaceDecl(iface) => todo("inner interface")
        }
    }

    private static func addThisToBlock(block: TypedBlock, fields: HashSet<String>): TypedBlock {
        let innerFields = fields.clone()
        block.map { d => addThisToDecl(d, innerFields) }
    }

    private static func addThisToExpr(expr: TypedExpr, fields: HashSet<String>): TypedExpr {
        let fExpr = { e => addThisToExpr(e, fields) }
        let fDecl = { e => addThisToDecl(e, fields) }
        let thisExpr = TypedExpr(ScVarRef("this"), TUnknown)
        match (expr.expr) {
            case ScVarRef(name) where fields.contains(name) => TypedExpr(ScMemberAccess(thisExpr, name), expr.ty)
            case ScBlockExpr(block) =>
                let decls = addThisToBlock(block, fields)
                TypedExpr(ScBlockExpr(decls), expr.ty) 
            case _ => AstUtils.mapExpr(expr, fExpr, fDecl)
        }
    }

    public static func addImplicitThisToFunc(fun: FuncDeclData, klass: ClassDeclData, scope: SymbolsScope): Unit {
        let fields = HashSet(collectFieldDeclarations(klass, scope)) 
        let args = fun.parameters.flatMap(getPatternNames)
        fields.remove(all: args)
        let body = addThisToBlock(fun.body, fields)
        fun.body = body
    }

}