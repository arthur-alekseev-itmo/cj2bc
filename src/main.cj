package cj2bc

import std.fs.File
import std.fs.OpenMode
import std.io.readString
import cj2bc.simpletree.parser.SimpleParser
import cj2bc.codegen.Codegen
import cj2bc.bytecode.BytecodeFile
import cj2bc.codegen.Linker
import std.argopt.*

import cj2bc.analysis.typing.*
import cj2bc.simpletree.pp.PpSimpleTree

main(args: Array<String>): Int64 {
    let argSpecs = [
        Full("input", r'i', RequiredValue),
        Full("output", r'o', RequiredValue),
        Full("print", r'p', OptionalValue)
    ]
    try {
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

        let inputFile = File(input, OpenMode.Read)
        let content = readString(inputFile)
        let simpleProgram = SimpleParser.parse(content)
        let scope = HierarhyCollect().collectHierarhy(simpleProgram)
        let inferredProgram = Inference().infer(simpleProgram, scope)
        PpSimpleTree.programToString(inferredProgram) |> println
        
        
        let state = Codegen().compileProgram(simpleProgram)
        Linker().link(state)


        if (print) {
            println(state.bytecode.toString())
            println(state.linkerData.toString())
        }

        let file = BytecodeFile(state.bytecode)
        file.save(output)

    } catch (e: ArgumentParseException) {
        println("Usage: error")
        return 1
    }

    return 0
}