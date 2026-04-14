func g() {
    print(3)
    return 0
}

func f() {
    print(2)
    g()
    print(4)
    return 0
}

main() {
    print(1)
    f()
    print(5)
    return 0
}