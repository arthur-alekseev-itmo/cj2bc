package cj2bc.utils

class TodoException <: Exception {
    public init() { }
    public init(message: String) {
        super(message)
    }
}

public func todo(message: String): Nothing {
    throw TodoException(message)
}

public func todo(): Nothing {
    throw TodoException()
}
