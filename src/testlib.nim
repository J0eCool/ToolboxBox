import math

proc positionForTime(t: float): float {.exportc, dynlib.} =
    200 + 100 * sin(t)
