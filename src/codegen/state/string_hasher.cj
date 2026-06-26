package cj2bc.codegen.state

import std.collection.HashMap

public class StringHashser {
    static let HASHES = HashMap<String, UInt32>()
    static var stringIndex = 0u32

    public static func getHash(s: String): UInt32 {
        match (HASHES.get(s)) {
            case None =>
                stringIndex++
                HASHES.add(s, stringIndex) 
                stringIndex
            case Some(hash) => hash
        }
    }

    public static func printStrings(): Unit {
        for ((k, v) in HASHES) {
            println("${v} ${k}")
        }
    }

    public static func reserveSymbols(): Unit {
        StringHashser.getHash("()")
        StringHashser.getHash("+")
        StringHashser.getHash("-")
        StringHashser.getHash("*")
        StringHashser.getHash("/")
        StringHashser.getHash("%")
        StringHashser.getHash("<")
        StringHashser.getHash("<=")
        StringHashser.getHash("==")
        StringHashser.getHash(">")
        StringHashser.getHash(">=")
        StringHashser.getHash("!=")
        StringHashser.getHash("-unary")
        StringHashser.getHash("!")
        // TODO: Other operators
    }
}
