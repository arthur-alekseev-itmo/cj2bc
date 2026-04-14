
// TODO: Func type
func mapPrint(f: Any, a: UInt32, b: UInt32, c: UInt32, d: UInt32, e: UInt32) {
    print(f(a))
    print(f(b))
    print(f(c))
    print(f(d))
    print(f(e))
    return 0
}

func f(x: UInt32): UInt32 {
    return x * 10
}

main(): Int64 {
    mapPrint(f, 1, 2, 3, 4, 5)
    return 0
}