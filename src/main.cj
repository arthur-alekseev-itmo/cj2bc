package cj2bc

import std.fs.File
import std.fs.OpenMode
import std.io.readString

import std.argopt.*

import cj2bc.parse.CjParser
import cj2bc.semantic.Analyzer
import cj2bc.prettyprint.PPAst
import cj2bc.codegen.state.StringHashser
import cj2bc.codegen.Codegen
import cj2bc.codegen.CodegenResult

main(args: Array<String>): Int64 {
    try {
        let argSpecs = [
            Full("input", r'i', RequiredValue),
            Full("output", r'o', RequiredValue),
            Full("print", r'p', OptionalValue)
        ]
        var result = parseArguments(args, argSpecs)

        let input = match (result.options.get("input")) {
            case Some(i) => i
            case None => throw Exception("Input must be specified")
        }

        let output = match (result.options.get("output")) {
            case Some(i) => i
            case None => "out.cjbc"
        }

        let print = match (result.options.get("print")) {
            case Some(i) => i == "" || i == "true"
            case None => false
        }

        // Reserve string hashes:
        // - operator overload
        // - some functions to be builtin
        // All to be overriden in interpreter
        StringHashser.reserveSymbols()
        

        let inputFile = File(input, OpenMode.Read)
        let content = readString(inputFile)
        let tree = CjParser.parse(content)
        let scope = Analyzer.analyze(tree)
        
        PPAst.programToString(tree) |> println
        
        let code = Codegen.codegen(tree, scope)

        if (print) {
            println(code.toString())
            StringHashser.printStrings()
        }

        let file = code.toFile()
        file.save(output)

    } catch (e: ArgumentParseException) {
        println("Usage: error")
        return 1
    }

    return 0
}