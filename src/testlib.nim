import math

import vec

# ---------------------------------
# hopefully can autogen this stuff from IDL

{.pragma:impfunc, cdecl.}
{.pragma:expfunc, cdecl, exportc, dynlib.}

type
    # kernel stuff for initialization
    Handle = pointer
    Loader = ptr object
        allocate: proc(size: Natural): pointer {.impfunc.}
        register: proc(hnd: Handle, name: cstring, f: pointer) {.impfunc.}
        lookup: proc(hnd: Handle, name: cstring): pointer {.impfunc.}

    # list of imported module handles
    # these are set up by the kernel and passed in, we keep a copy of them
    # in order to call back correctly
    Imports = object
        renderer: Handle
        setRGB: proc(renderer: Handle, r, g, b: int) {.impfunc.}
        drawBox: proc(renderer: Handle, pos, size: Vec) {.impfunc.}
        drawText: proc(hnd: Handle, pos: Vec, text: cstring) {.impfunc.}

        input: Handle
        isKeyHeld: proc(input: Handle, key: char): bool {.impfunc.}
        wasKeyPressed: proc(input: Handle, key: char): bool {.impfunc.}
        mousePos: proc(input: Handle): Vec {.impfunc.}
        wasMouseReleased: proc(input: Handle, button: int): bool {.impfunc.}

    # this module
    Module = ptr ModuleObj
    ModuleObj = object
        imports: Imports

        pos: Vec

# convenience methods
proc setRGB(module: Module, r, g, b: int) {.inline.} =
    module.imports.setRGB(module.imports.renderer, r, g, b)
proc drawBox(module: Module, pos, size: Vec) {.inline.} =
    module.imports.drawBox(module.imports.renderer, pos, size)
proc drawText(module: Module, pos: Vec, text: string) {.inline.} =
    module.imports.drawText(module.imports.renderer, pos, text.cstring)

proc isKeyHeld(module: Module, key: char): bool {.inline.} =
    module.imports.isKeyHeld(module.imports.input, key)
proc wasKeyPressed(module: Module, key: char): bool {.inline.} =
    module.imports.wasKeyPressed(module.imports.input, key)
proc mousePos(module: Module): Vec {.inline.} =
    module.imports.mousePos(module.imports.input)
proc wasMouseReleased(module: Module, button: int): bool {.inline.} =
    module.imports.wasMouseReleased(module.imports.input, button)

# forward declarations + wrapper functions
proc update(module: Module, t: float) {.cdecl.}

proc initialize(smeef: Handle, loader: Loader) {.expfunc.} =
    loader.register(smeef, "update", update)

proc construct(loader: Loader, imports: ptr Imports): Module {.expfunc.} =
    result = cast[Module](loader.allocate(sizeof(ModuleObj)))
    result.imports = imports[]

# end autogen
# ---------------------------------

proc start(module: Module) {.expfunc.} =
    module.pos = vec(300, 30)

proc update(module: Module, t: float) {.cdecl.} =
    let pos = vec(120 + 10 * cos(5 * t), 200 + 100 * sin(t))
    module.setRGB(128, 64, 255)
    module.drawBox(pos, vec(40, 40))

    let speed = 5.0
    if module.isKeyHeld('a'):
        module.pos.x -= speed
    if module.isKeyHeld('d'):
        module.pos.x += speed
    if module.isKeyHeld('w'):
        module.pos.y -= speed
    if module.isKeyHeld('s'):
        module.pos.y += speed

    if module.wasKeyPressed('j'):
        module.pos = module.pos + vec(50, 50)

    module.drawBox(module.pos, vec(40, 40))

    module.setRGB(128, 255, 255)
    module.drawText(vec(600, 200), "player: " & $module.pos)
    module.drawText(vec(600, 300), "mouse: " & $module.mousePos())
    if module.wasMouseReleased(1):
        module.drawText(vec(600, 400), "CLICKED")
