import tables

import common

const numKeys = 256

type
    KeyState = enum
        # high bit for "is key down"
        # low bit is for "was key pressed/released this frame"
        ksReleased = 0b00
        ksWentUp = 0b01
        ksHeld = 0b10
        ksWentDown = 0b11

    Imports = object

    InputModule* = ptr InputModuleObj
    InputModuleObj = object
        keys: array[numKeys, KeyState]

# currently copy-pasting across system modules; maybe unify? maybe don't?
var loadedModules: Table[Handle, InputModule]
proc lookup(handle: Handle): InputModule =
    result = loadedModules[handle]
    assert result != nil

# wrappers for public functions

proc isKeyHeld(module: InputModule, key: char): bool
proc wrap_isKeyHeld(handle: Handle, key: char): bool {.cdecl.} =
    isKeyHeld(lookup(handle), key)
proc wasKeyPressed(module: InputModule, key: char): bool
proc wrap_wasKeyPressed(handle: Handle, key: char): bool {.cdecl.} =
    wasKeyPressed(lookup(handle), key)

# standard module hooks

proc initialize*(hnd: Handle, loader: Loader, imports: ptr Imports): InputModule =
    result = cast[InputModule](loader.allocate(hnd, sizeof(InputModuleObj)))
    loadedModules[hnd] = result
    loader.register(hnd, "isKeyHeld", wrap_isKeyHeld)
    loader.register(hnd, "wasKeyPressed", wrap_wasKeyPressed)

proc start*(module: InputModule) =
    discard

proc cleanup*(module: InputModule) =
    discard

# system level special hooks

proc onKeyDown*(module: InputModule, key: int) =
    # TODO: translate SDL keys to some custom scheme
    # also figure out how to bind enums across IDL :|
    # until then, 'a' 'b' etc correspond 1-1 so good enough for now
    if key < numKeys:
        module.keys[key] = ksWentDown

proc onKeyUp*(module: InputModule, key: int) =
    if key < numKeys:
        module.keys[key] = ksWentUp

proc update*(module: InputModule) =
    for k in 0..<numKeys:
        # mask off the low bit
        module.keys[k] = KeyState(module.keys[k].int and 2)

# exported functions

proc isKeyHeld(module: InputModule, key: char): bool =
    (module.keys[key.int].int and 2) != 0

proc wasKeyPressed(module: InputModule, key: char): bool =
    module.keys[key.int] == ksWentDown
