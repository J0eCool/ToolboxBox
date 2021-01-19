import math

import vec

{.pragma:expfunc, cdecl, exportc, dynlib.}

proc positionForTime(t: float): Vec {.expfunc.} =
    vec(120 + 10 * cos(5 * t), 200 + 100 * sin(t))

proc update(t: float, draw: proc(pos: Vec) {.cdecl.}) {.expfunc.} =
    draw(vec(300, 30))
