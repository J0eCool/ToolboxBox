import math

import vec

# ---------------------------------
# hopefully can autogen this stuff from IDL

{.pragma:expfunc, cdecl, exportc, dynlib.}
{.pragma:impfunc, cdecl.}

type
    # kernel stuff for initialization
    Handle = distinct int
    Loader = ptr object
        allocate: proc(hnd: Handle, size: Natural): pointer {.impfunc.}
        register: proc(module: pointer, name: string, f: pointer) {.impfunc.}

    # foreign module
    Renderer = ptr object
        drawBox_ptr: proc(renderer: Renderer, pos, size: Vec) {.impfunc.}

    # this module
    Context = ptr ContextObj
    ContextObj = object
        update: proc(ctx: Context, t: float) {.cdecl.}
        # private field comes after exports (yikes)
        renderer: Renderer

# convenience methods
proc drawBox(renderer: Renderer, pos, size: Vec) =
    renderer.drawBox_ptr(renderer, pos, size)

# forward declarations
proc update(ctx: Context, t: float) {.cdecl.}

proc initialize(hnd: Handle, loader: Loader, renderer: Renderer): Context {.expfunc.} =
    result = cast[Context](loader.allocate(hnd, sizeof(Context)))
    result.renderer = renderer
    loader.register(result, "update", update)

# end autogen
# ---------------------------------

proc update(ctx: Context, t: float) {.cdecl.} =
    let pos = vec(120 + 10 * cos(5 * t), 200 + 100 * sin(t))
    ctx.renderer.drawBox(pos, vec(40, 40))

    ctx.renderer.drawBox(vec(300, 30), vec(40, 40))
