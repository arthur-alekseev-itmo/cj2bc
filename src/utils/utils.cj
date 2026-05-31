package cj2bc.utils

class TodoException <: Exception {

}

public func todo(): Nothing {
    throw TodoException()
}
