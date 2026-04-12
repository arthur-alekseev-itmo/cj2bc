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

//B_0000 LoadLocal 0
//B_0001 LoadLocal 0
//B_0002 LoadImm 32
//B_0003 CallRef
//B_0004 CallRef
//B_0005 Drop
//B_0006 LoadImm 0
//B_0007 Drop

//B_0008 StoreLocal 0
//B_0009 LoadLocal 0
//B_0010 LoadImm 2
//B_0011 Lt
//B_0012 JumpTrue 4294967295
//B_0013 LoadLocal 0
//B_0014 Return
//B_0015 Drop
//B_0016 Jump 4294967295
//B_0017 Drop
//B_0018 LoadLocal 0
//B_0019 LoadLocal 0
//B_0020 LoadImm 2
//B_0021 Sub
//B_0022 CallRef
//B_0023 LoadLocal 0
//B_0024 LoadLocal 0
//B_0025 LoadImm 1
//B_0026 Sub
//B_0027 CallRef
//B_0028 Add
//B_0029 Drop
//
//RELOCATIONS
//Symbol: $BRANCH_ELSE_1, Instruction: 1, Position: 13, Size: 4
//Symbol: $BRANCH_END_1, Instruction: 1, Position: 17, Size: 4
//LOCATIONS
//main: 0
//fib: 8
//$BRANCH_ELSE_1: 17
//$BRANCH_END_1: 17