package  cj2bc.bytecode
import std.collection.ArrayList
import cj2bc.bytecode.util.appendInt32
import std.fs
import std.fs.File
import std.fs.OpenMode

public struct BytecodeFileHeader {
    let magic: UInt32 = 0x67746667
    let size: UInt32

    init(size: UInt32) {
        this.size = size
    }

    private func serializeTo(target: ArrayList<Byte>) {
        appendInt32(magic, target)
        appendInt32(size, target)
    }

    public func serialize() {
        let result = ArrayList<Byte>()
        serializeTo(result)
        result
    }
}

public class BytecodeFile {
    let bytecode: Bytecode
    let serializedBytecode: ArrayList<Byte>
    let header: BytecodeFileHeader

    public BytecodeFile(bytecode: Bytecode) {
        this.bytecode = bytecode
        this.serializedBytecode = bytecode.serialize()
        this.header = BytecodeFileHeader(UInt32(serializedBytecode.size))
    }

    public func save(filename: String) {
        let file = File(filename, OpenMode.Write)
        file.write(header.serialize().toArray())
        file.write(serializedBytecode.toArray())
        file.flush()
        file.close()
    }
}
