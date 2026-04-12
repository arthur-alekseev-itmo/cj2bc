func odd(x: Int64): Bool {
    return if (x == 0) {
        false
    } else {
        !even(x)
    }
}

func even(x: Int64): Bool {
    if (x == 0) {
        return true
    }
    return !odd(x)
}

main(): Int64 {
    print(even(10))
    return 0
}