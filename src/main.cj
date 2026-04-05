package cj2bc

import std.fs.File
import std.fs.OpenMode
import std.io.readString
import cj2bc.simpletree.SimpleParser


main(): Int64 {
    let exampleFib = "/Users/arthur/Documents/cj2bc/example/variables.cj"
    let input = File(exampleFib, OpenMode.Read)
    let content = readString(input)

    // parseProgram(cangjieLex(content)).dump()
    let simpleTree = SimpleParser().parse(content)
    0
}