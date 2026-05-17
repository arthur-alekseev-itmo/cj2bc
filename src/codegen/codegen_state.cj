package cj2bc.codegen

import cj2bc.bytecode.Bytecode
import std.collection.HashMap
import cj2bc.analysis.SymbolsScope

public class CodegenState {
    public let bytecode: Bytecode
    public let classes: HashMap<String, ClassData>
    public let linkerData: LinkerData 
    public let locals: LocalsContextFrame 
    public let scope: SymbolsScope
    
    public func enterSymbol(symbol: String): CodegenState {
        let newScope = scope.enterSymbol(symbol)
        let newState = CodegenState(newScope, this)
        newState
    }

    public init(scope: SymbolsScope) {
        this.scope = scope
        this.classes = HashMap<String, ClassData>()
        this.bytecode = Bytecode()
        this.linkerData = LinkerData()
        this.locals = LocalsContextFrame()
    }

    public init(newScope: SymbolsScope, parent: CodegenState) {
        this.scope = newScope
        this.classes = parent.classes
        this.bytecode = parent.bytecode
        this.linkerData = parent.linkerData 
        this.locals = LocalsContextFrame(parent.locals) 
    }
}
