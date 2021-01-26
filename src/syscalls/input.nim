import common

const numKeys = 256

type
    KeyState = enum
        Released = 0
        WentUp = 1
        Held = 2
        WentDown = 3

    Imports = object

    InputModule* = ptr InputModuleObj
    InputModuleObj = object
        keys: array[numKeys, KeyState]

proc initialize*(hnd: Handle, loader: Loader, imports: ptr Imports): InputModule =
    result = cast[InputModule](loader.allocate(hnd, sizeof(InputModuleObj)))
