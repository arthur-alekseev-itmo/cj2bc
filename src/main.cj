package cj2bc

import std.fs.File
import std.fs.OpenMode
import std.io.readString
import cj2bc.simpletree.SimpleParser
import cj2bc.codegen.Codegen

main(): Int64 {
    let exampleFib = "/Users/arthur/Documents/cj2bc/example/fib.cj"
    let input = File(exampleFib, OpenMode.Read)
    let content = readString(input)

    let simpleProgram = SimpleParser().parse(content)
    let state = Codegen().compileProgram(simpleProgram)
    println(state.bytecode.toString())
    println(state.linkerData.toString())
    0
}