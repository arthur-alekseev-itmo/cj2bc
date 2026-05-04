package cj2bc.utils

class TodoException <: Exception {

}

public func todo() {
    throw TodoException()
}

var counter = 0
public func nextCnt() {
    counter++
    counter
}