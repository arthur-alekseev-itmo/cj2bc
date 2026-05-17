package cj2bc.bytecode

import std.collection.ArrayList
import cj2bc.bytecode.util.appendInt32
import std.fs.File
import std.fs.OpenMode
import cj2bc.bytecode.util.*

public struct BytecodeMemberEntry {
    private let name: UInt32
    private let typ: UInt32
    private let offset: UInt32

    public init(name: UInt32, typ: UInt32, offset: UInt32) {
        this.name = name
        this.typ = typ
        this.offset = offset
    }

    public func serializeTo(target: ArrayList<Byte>): Unit {
        appendInt32(name, target)
        appendInt32(typ, target)
        appendInt32(offset, target)
    }
}

public struct BytecodeClassHeader {
    private let name: UInt32
    private let base: UInt32
    private let members: ArrayList<BytecodeMemberEntry>
    private let interfaces: ArrayList<UInt32>

    public init(name: UInt32, base: UInt32) {
        this.name = name
        this.base = base
        this.members = ArrayList<BytecodeMemberEntry>()
        this.interfaces = ArrayList<UInt32>()
    }

    public func addMember(entry: BytecodeMemberEntry): Unit {
        this.members.add(entry)
    }

    public func getSizeInBytes(): UInt32 {
        let INT_SIZE = 4u32
        let MEMBER_SIZE = 12u32
        return 4 * INT_SIZE + UInt32(members.size) * MEMBER_SIZE
    }

    public func serializeTo(target: ArrayList<Byte>): Unit {
        appendInt32(name, target)
        appendInt32(base, target)
        appendInt32(UInt32(interfaces.size), target) 
        appendInt32(UInt32(members.size), target)
        members.map { d => d.serializeTo(target) }
    }
}

public class BytecodeClassesHeader {
    private let classes: ArrayList<BytecodeClassHeader>

    public init() {
        this.classes = ArrayList<BytecodeClassHeader>()
    }

    public func addClass(header: BytecodeClassHeader): Unit {
        this.classes.add(header)
    }

    public func getSizeInBytes(): UInt32 {
        return 4 + classes.map { c => c.getSizeInBytes() }.fold(0) { a, b => a + b }
    }

    public func serializeTo(target: ArrayList<Byte>): Unit {
        appendInt32(UInt32(classes.size), target)
        classes.map { c => c.serializeTo(target) }
    } 
}

public struct BytecodeBytecodeHeader {
    private let bytecode: Bytecode
    private let size: UInt32

    // TODO: Adequate Size estimation here
    public init(bytecode: Bytecode) {
        this.bytecode = bytecode
        this.size = UInt32(bytecode.serialize().size)
    }

    public func getSizeInBytes(): UInt32 {
        this.size + 4
    }

    public func serializeTo(target: ArrayList<Byte>): Unit {
        appendInt32(size, target)
        bytecode.serializeTo(target)
    }
}


public class BytecodeFile {
    let classes: BytecodeClassesHeader
    let bytecode: BytecodeBytecodeHeader

    public BytecodeFile(classes: BytecodeClassesHeader, bytecode: BytecodeBytecodeHeader) {
        this.bytecode = bytecode
        this.classes = classes
    }

    public func serializeTo(target: ArrayList<Byte>): Unit {
        let INT_SIZE = 4u32
        let selfSize = INT_SIZE * 5u32
        let classesSize = classes.getSizeInBytes()
        let bytecodeSize = bytecode.getSizeInBytes()
        let totalSize = selfSize + classesSize + bytecodeSize
        let magic = 0x46424a43u32
        appendInt32(magic, target)
        appendInt32(totalSize, target)
        appendInt32(selfSize, target)
        appendInt32(selfSize + classesSize, target)
        appendInt32(selfSize + classesSize + bytecodeSize, target)
        classes.serializeTo(target)
        bytecode.serializeTo(target)
    }

    public func save(filename: String): Unit {
        let file = File(filename, OpenMode.Write)
        let array = ArrayList<Byte>()
        serializeTo(array)
        file.write(array.toArray())
        file.flush()
        file.close()
    }
}
