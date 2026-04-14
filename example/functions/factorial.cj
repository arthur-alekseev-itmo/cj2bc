func factorial(i: UInt64): UInt64 {
    if (i == 1) {
        return 1
    }
    return i * factorial(i - 1)
}

main(): Int64 {
    print(factorial(10))
    return 0
}