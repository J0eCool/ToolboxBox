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
        mousePos: proc(input: Handle): Vec {.impfunc.}
        wasMouseReleased: proc(input: Handle, button: int): bool {.impfunc.}

    # this module
    Module = ptr ModuleObj
    ModuleObj = object
        imports: Imports

# convenience methods
proc setRGB(module: Module, r, g, b: int) {.inline.} =
    module.imports.setRGB(module.imports.renderer, r, g, b)
proc drawBox(module: Module, pos, size: Vec) {.inline.} =
    module.imports.drawBox(module.imports.renderer, pos, size)
proc drawText(module: Module, pos: Vec, text: string) {.inline.} =
    module.imports.drawText(module.imports.renderer, pos, text.cstring)

proc mousePos(module: Module): Vec {.inline.} =
    module.imports.mousePos(module.imports.input)
proc wasMouseReleased(module: Module, button: int): bool {.inline.} =
    module.imports.wasMouseReleased(module.imports.input, button)

# forward declarations + wrapper functions
proc button(module: Module, text: cstring, pos, size: Vec): bool {.cdecl.}

proc initialize(smeef: Handle, loader: Loader) {.expfunc.} =
    loader.register(smeef, "button", button)

proc construct(loader: Loader, imports: ptr Imports): Module {.expfunc.} =
    result = cast[Module](loader.allocate(sizeof(ModuleObj)))
    result.imports = imports[]

# end autogen
# ---------------------------------

proc button(module: Module, text: cstring, pos, size: Vec): bool {.cdecl.} =
    let
        br = pos + size
        mouse = module.mousePos()
        isMouseOver = (mouse.x >= pos.x and mouse.x <= br.x and
            mouse.y >= pos.y and mouse.y <= br.y)

    if isMouseOver:
        module.setRGB(160, 160, 128)
    else:
        module.setRGB(92, 92, 92)
    module.drawBox(pos, size)

    # TODO: drawCenteredText method
    let labelPos = pos + size/2 - vec(size.x/4, 0)
    module.setRGB(255, 255, 255)
    module.drawText(labelPos, $text)

    return isMouseOver and module.wasMouseReleased(1)
