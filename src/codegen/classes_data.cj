package cj2bc.codegen

import std.collection.ArrayList
import std.deriving.Derive
import cj2bc.bytecode.*

@Derive[ToString]
public enum MemberType {
    | MtField
    | MtCtor
    | MtMethod

    public func toUInt32(): UInt32 {
        match (this) {
            case MtField => 0x1
            case MtMethod => 0x2
            case MtCtor => 0x4
        }
    }
}

public class MemberData <: ToString {
    private let typ: MemberType
    private let offset: UInt32
    private let name: String

    public init(name: String, typ: MemberType, offset: UInt32) {
        this.name = name
        this.typ = typ
        this.offset = offset
    }

    public func toString(): String {
        "${typ} ${name} ${offset}"
    }

    public func toMemberEntry(): BytecodeMemberEntry {
        BytecodeMemberEntry(StringHashser.getHash(name), typ.toUInt32(), offset)
    }
}

public class ClassData <: ToString {
    private let name: String
    private let members: ArrayList<MemberData>

    public init(name: String) {
        this.name = name
        this.members = ArrayList<MemberData>()
    }

    public func addMethod(name: String, offset: UInt32): Unit {
        let member = MemberData(name, MtMethod, offset)
        members.add(member)
    }

    public func addCtor(name: String, offset: UInt32): Unit {
        let member = MemberData(name, MtCtor, offset)
        members.add(member)
    }

    public func toString(): String {
        let memberStrings = members.map { x => "- ${x}" }.toArray()
        let memberList = String.join(memberStrings, delimiter:"\n")
        "Class: ${name}\n${memberList}\n"
    }

    public func toClassHeader(): BytecodeClassHeader {
        let header = BytecodeClassHeader(StringHashser.getHash(name), 0)
        members.map { m: MemberData => header.addMember(m.toMemberEntry()) }
        header
    }
}