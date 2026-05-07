package cj2bc.bytecode

import std.collection.ArrayList

struct CjClass {
    let magic: UInt32 = 0x434a4346 // CJCF
    let methods: CjMethodTable = CjMethodTable()
    let fields: CjFieldTable = CjFieldTable()
}

struct CjMethodTable {
    let methods: ArrayList<CjMethodEntry> = ArrayList()
}

struct CjFieldTable {
    let fields: ArrayList<CjFieldEntry> = ArrayList()
}

struct CjMethodEntry {
    let methodName: UInt32
    let bytecodeOffset: UInt32

    public CjMethodEntry(methodName: UInt32, bytecodeOffset: UInt32) {
        this.methodName = methodName
        this.bytecodeOffset = bytecodeOffset
    }
}

struct CjFieldEntry {
    let fieldName: UInt32
    let offset: UInt32

    public CjFieldEntry(fieldName: UInt32, offset: UInt32) {
        this.fieldName = fieldName
        this.offset = offset
    }
}
