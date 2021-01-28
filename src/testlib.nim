import math

import vec

# ---------------------------------
# hopefully can autogen this stuff from IDL

import tables

{.pragma:impfunc, cdecl.}
{.pragma:expfunc, cdecl, exportc, dynlib.}

type
    # kernel stuff for initialization
    Handle = distinct int
    Loader = ptr object
        allocate: proc(hnd: Handle, size: Natural): pointer {.impfunc.}
        register: proc(hnd: Handle, name: cstring, f: pointer) {.impfunc.}
        lookup: proc(hnd: Handle, name: cstring): pointer {.impfunc.}

    # list of imported module handles
    # these are set up by the kernel and passed in, we keep a copy of them
    # in order to call back correctly
    Imports = object
        renderer: Handle
        input: Handle

    # foreign module
    Renderer = object
        drawBox: proc(renderer: Handle, pos, size: Vec) {.impfunc.}
    Input = object
        isKeyHeld: proc(input: Handle, key: char): bool {.impfunc.}
        wasKeyPressed: proc(input: Handle, key: char): bool {.impfunc.}

    # this module
    Module = ptr ModuleObj
    ModuleObj = object
        imports: Imports
        renderer: Renderer
        input: Input

        pos: Vec

proc `==`(a, b: Handle): bool {.borrow.}

var loadedModules: Table[Handle, Module]
proc lookup(handle: Handle): Module =
    result = loadedModules[handle]
    assert result != nil

# convenience methods
proc drawBox(module: Module, pos, size: Vec) {.inline.} =
    module.renderer.drawBox(module.imports.renderer, pos, size)

proc isKeyHeld(module: Module, key: char): bool {.inline.} =
    module.input.isKeyHeld(module.imports.input, key)
proc wasKeyPressed(module: Module, key: char): bool {.inline.} =
    module.input.wasKeyPressed(module.imports.input, key)

# forward declarations + wrapper functions
proc update(module: Module, t: float)
proc wrap_update(handle: Handle, t: float) {.cdecl.} =
    update(lookup(handle), t)

proc initialize(hnd: Handle, loader: Loader, imports: ptr Imports): Module {.expfunc.} =
    result = cast[Module](loader.allocate(hnd, sizeof(ModuleObj)))
    loadedModules[hnd] = result
    result.imports = imports[]
    loader.register(hnd, "update", wrap_update)

    result.renderer.drawBox = cast[proc(hnd: Handle, pos, size: Vec) {.impfunc.}](
        loader.lookup(imports.renderer, "drawBox"))
    result.input.isKeyHeld = cast[proc(hnd: Handle, key: char): bool {.impfunc.}](
        loader.lookup(imports.input, "isKeyHeld"))
    result.input.wasKeyPressed = cast[proc(hnd: Handle, key: char): bool {.impfunc.}](
        loader.lookup(imports.input, "wasKeyPressed"))

    result.pos = vec(300, 30)

# end autogen
# ---------------------------------

proc update(module: Module, t: float) =
    let pos = vec(120 + 10 * cos(5 * t), 200 + 100 * sin(t))
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
