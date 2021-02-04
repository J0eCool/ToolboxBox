import tables

import common
import ../vec

const
    numKeys = 256
    numMouseButtons = 5

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
        mouseX, mouseY: int
        # not sure what to do w/ mouse buttons:
        #  1 = left
        #  2 = middle
        #  3 = right
        mouseButtons: array[numMouseButtons, KeyState]

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
proc wasKeyReleased(module: InputModule, key: char): bool
proc wrap_wasKeyReleased(handle: Handle, key: char): bool {.cdecl.} =
    wasKeyReleased(lookup(handle), key)
proc mousePos(module: InputModule): Vec
proc wrap_mousePos(handle: Handle): Vec {.cdecl.} =
    mousePos(lookup(handle))
proc wasMousePressed(module: InputModule, button: int): bool
proc wrap_wasMousePressed(handle: Handle, button: int): bool {.cdecl.} =
    wasMousePressed(lookup(handle), button)
proc wasMouseReleased(module: InputModule, button: int): bool
proc wrap_wasMouseReleased(handle: Handle, button: int): bool {.cdecl.} =
    wasMouseReleased(lookup(handle), button)

# standard module hooks

proc initialize*(hnd: Handle, loader: Loader, imports: ptr Imports): InputModule =
    result = cast[InputModule](loader.allocate(hnd, sizeof(InputModuleObj)))
    loadedModules[hnd] = result
    loader.register(hnd, "isKeyHeld", wrap_isKeyHeld)
    loader.register(hnd, "wasKeyPressed", wrap_wasKeyPressed)
    loader.register(hnd, "wasKeyReleased", wrap_wasKeyReleased)
    loader.register(hnd, "mousePos", wrap_mousePos)
    loader.register(hnd, "wasMousePressed", wrap_wasMousePressed)
    loader.register(hnd, "wasMouseReleased", wrap_wasMouseReleased)

proc start*(module: InputModule) =
    discard

proc cleanup*(module: InputModule) =
    discard

# system level special hooks

# TODO: translate SDL keys to some custom scheme
# also figure out how to bind enums across IDL :|
# until then, 'a' 'b' etc correspond 1-1 so good enough for now
func sdlToKey(key: int): int =
    if key >= numKeys:
        0
    else:
        key

proc onKeyDown*(module: InputModule, sdlKey: int) =
    let key = sdlToKey(sdlKey)
    # don't set WentDown if key is still Held, because OS-level key repetition
    if module.keys[key] != ksHeld:
        module.keys[key] = ksWentDown

proc onKeyUp*(module: InputModule, sdlKey: int) =
    let key = sdlToKey(sdlKey)
    module.keys[key] = ksWentUp

proc onMouseMotion*(module: InputModule, x, y: int) =
    module.mouseX = x
    module.mouseY = y

proc onMouseDown*(module: InputModule, button: int) =
    module.mouseButtons[button] = ksWentDown
proc onMouseUp*(module: InputModule, button: int) =
    module.mouseButtons[button] = ksWentUp

proc update*(module: InputModule) =
    # mask off the low bit
    for k in 0..<numKeys:
        module.keys[k] = KeyState(module.keys[k].int and 2)
    for b in 0..<numMouseButtons:
        module.mouseButtons[b] = KeyState(module.mouseButtons[b].int and 2)

# exported functions

proc isKeyHeld(module: InputModule, key: char): bool =
    (module.keys[key.int].int and 2) != 0

proc wasKeyPressed(module: InputModule, key: char): bool =
    module.keys[key.int] == ksWentDown
proc wasKeyReleased(module: InputModule, key: char): bool =
    module.keys[key.int] == ksWentUp

proc mousePos(module: InputModule): Vec =
    vec(module.mouseX.float, module.mouseY.float)

proc wasMousePressed(module: InputModule, button: int): bool =
    module.mouseButtons[button] == ksWentDown
proc wasMouseReleased(module: InputModule, button: int): bool =
    module.mouseButtons[button] == ksWentUp
