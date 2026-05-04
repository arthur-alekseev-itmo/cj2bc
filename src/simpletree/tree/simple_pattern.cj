package cj2bc.simpletree.tree

import cj2bc.analysis.typing.types.Type

public enum SimplePattern {
    | ScVariable(String, ?SimpleType)
}
