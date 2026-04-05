package cj2bc.bytecode.util

import std.collection.ArrayList

public func appendInt32(n: UInt32, bc: ArrayList<Byte>){
    bc.add(UInt8(n & 0xFF))
    bc.add(UInt8((n >> 8) & 0xFF))
    bc.add(UInt8((n >> 16) & 0xFF))
    bc.add(UInt8((n >> 24) & 0xFF))
}

public func appendInt64(n: UInt64, bc: ArrayList<Byte>){
    bc.add(UInt8(n & 0xFF))
    bc.add(UInt8((n >> 8) & 0xFF))
    bc.add(UInt8((n >> 16) & 0xFF))
    bc.add(UInt8((n >> 24) & 0xFF))
    bc.add(UInt8((n >> 32) & 0xFF))
    bc.add(UInt8((n >> 40) & 0xFF))
    bc.add(UInt8((n >> 48) & 0xFF))
    bc.add(UInt8((n >> 56) & 0xFF))
}

public func zeroExtend(padding: Int64, content: Int64) {
    let serialized = content.toString()
    let zeroCount = padding - serialized.size
    if (zeroCount <= 0) {
        return serialized
    }
    return "0" * zeroCount + serialized
}