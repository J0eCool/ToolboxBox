import math

import vec

# ---------------------------------
# hopefully can autogen this stuff from IDL

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

    # foreign module
    Renderer = object
        drawBox: proc(renderer: Handle, pos, size: Vec) {.impfunc.}

    # this module
    Module = ptr ModuleObj
    ModuleObj = object
        imports: Imports
        renderer: Renderer

# convenience methods
proc drawBox(module: Module, pos, size: Vec) =
    module.renderer.drawBox(module.imports.renderer, pos, size)

# forward declarations
proc update(module: Module, t: float) {.cdecl.}

proc initialize(hnd: Handle, loader: Loader, imports: ptr Imports): Module {.expfunc.} =
    result = cast[Module](loader.allocate(hnd, sizeof(ModuleObj)))
    result.imports = imports[]
    loader.register(hnd, "update", update)

    result.renderer.drawBox = cast[proc(hnd: Handle, pos, size: Vec) {.impfunc.}](
        loader.lookup(imports.renderer, "drawBox"))

# end autogen
# ---------------------------------

proc update(module: Module, t: float) {.cdecl.} =
    let pos = vec(120 + 10 * cos(5 * t), 200 + 100 * sin(t))
    module.drawBox(pos, vec(40, 40))

    module.drawBox(vec(300, 30), vec(40, 40))
