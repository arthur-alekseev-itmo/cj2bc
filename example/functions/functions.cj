func f(x: UInt64): UInt64 {
    return x + 3
}

func g(x: UInt64): UInt64 {
    return x * 2
}

main(): Int64 {
    print(g(f(15)))
    return 0
}