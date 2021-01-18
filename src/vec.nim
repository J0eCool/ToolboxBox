import math

type Vec* = object
    x*: float
    y*: float

func vec*(x, y: float): Vec =
    Vec(x: x, y: y)

# TODO: check ABI differences (either of these works)
# type Vec* = tuple[x, y: float]

# func vec*(x, y: float): Vec =
#     (x, y)

template binOp(op: untyped) =
    proc op*(a, b: Vec): Vec =
        vec(op(a.x, b.x), op(a.y, b.y))

binOp `+`
binOp `-`
binOp `*`
binOp `/`
