# import math

type Vec* = object
    x*: float
    y*: float

func vec*(x, y: float): Vec =
    Vec(x: x, y: y)

template binOp(op: untyped) =
    func op*(a, b: Vec): Vec =
        vec(op(a.x, b.x), op(a.y, b.y))

    func op*(v: Vec, s: float): Vec =
        vec(op(v.x, s), op(v.y, s))
    func op*(s: float, v: Vec): Vec =
        vec(op(s, v.x), op(s, v.y))

binOp `+`
binOp `-`
binOp `*`
binOp `/`
