package cj2bc.semantic.collect

import cj2bc.ast.tree.CjProgram
import cj2bc.common.SymbolsScope

public class Collect {
    public static func collect(program: CjProgram): SymbolsScope {
        return CollectTypes().collectHierarhy(program)
    }
}