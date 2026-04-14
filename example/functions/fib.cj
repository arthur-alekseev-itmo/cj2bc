func fib(x: Int64): Int64 {
    if (x < 3) {
        return 1
    }
    return fib(x - 2) + fib(x - 1)
}

main(): Int64 {
    print(fib(10))
    return 0
}
