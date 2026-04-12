func fib(x: Int64): Int64 {
    if (x < 2) {
        return x
    }
    return fib(x - 2) + fib(x - 1)
}

main(): Int64 {
    print(fib(32))
    return 0
}
