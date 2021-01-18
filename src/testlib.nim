import math

import vec

proc positionForTime(t: float): Vec {.cdecl, exportc, dynlib.} =
    vec(120 + 10 * cos(5 * t), 200 + 100 * sin(t))
