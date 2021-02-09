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
    InputModuleObj = object of ZarbObj
        keys: array[numKeys, KeyState]
        mouseX, mouseY: int
        # not sure what to do w/ mouse buttons:
        #  1 = left
        #  2 = middle
        #  3 = right
        mouseButtons: array[numMouseButtons, KeyState]

# wrappers for public functions

proc isKeyHeld(module: InputModule, key: char): bool {.cdecl.}
proc wasKeyPressed(module: InputModule, key: char): bool {.cdecl.}
proc wasKeyReleased(module: InputModule, key: char): bool {.cdecl.}
proc mousePos(module: InputModule): Vec {.cdecl.}
proc wasMousePressed(module: InputModule, button: int): bool {.cdecl.}
proc wasMouseReleased(module: InputModule, button: int): bool {.cdecl.}

# standard module hooks

proc initialize*(smeef: Smeef, loader: Loader) =
    loader.register(smeef, "isKeyHeld", isKeyHeld)
    loader.register(smeef, "wasKeyPressed", wasKeyPressed)
    loader.register(smeef, "wasKeyReleased", wasKeyReleased)
    loader.register(smeef, "mousePos", mousePos)
    loader.register(smeef, "wasMousePressed", wasMousePressed)
    loader.register(smeef, "wasMouseReleased", wasMouseReleased)

proc construct*(loader: Loader, imports: ptr Imports): InputModule =
    result = cast[InputModule](loader.allocate(sizeof(InputModuleObj)))

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

proc isKeyHeld(module: InputModule, key: char): bool {.cdecl.} =
    (module.keys[key.int].int and 2) != 0

proc wasKeyPressed(module: InputModule, key: char): bool {.cdecl.} =
    module.keys[key.int] == ksWentDown
proc wasKeyReleased(module: InputModule, key: char): bool {.cdecl.} =
    module.keys[key.int] == ksWentUp

proc mousePos(module: InputModule): Vec {.cdecl.} =
    vec(module.mouseX.float, module.mouseY.float)

proc wasMousePressed(module: InputModule, button: int): bool {.cdecl.} =
    module.mouseButtons[button] == ksWentDown
proc wasMouseReleased(module: InputModule, button: int): bool {.cdecl.} =
    module.mouseButtons[button] == ksWentUp
