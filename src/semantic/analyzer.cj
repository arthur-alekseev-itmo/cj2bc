package cj2bc.semantic

import cj2bc.ast.tree.CjProgram
import cj2bc.semantic.collect.Collect
import cj2bc.semantic.transform.Desugar
import cj2bc.semantic.types.Inference
import cj2bc.common.SymbolsScope

import cj2bc.prettyprint.PPAst

public class Analyzer {
    public static func analyze(program: CjProgram): SymbolsScope {
        let scope = Collect.collect(program)
        Desugar.transform(program, scope)
        Inference.infer(program, scope)
        scope
    }
}