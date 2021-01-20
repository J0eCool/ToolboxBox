import math

import vec


# {.pragma:expfunc, cdecl, exportc, dynlib.}
# {.pragma impfunc: cdecl.}

type
    Renderer = ptr object
    Imports = ptr object
        allocate: proc(t: Natural): pointer {.cdecl.}
        drawBox: proc(imports: Imports, pos, size: Vec) {.cdecl.}

    Context = ptr ContextObj
    ContextObj = object
        update: proc(ctx: Context, t: float) {.cdecl.}
        # private field comes after exports (yikes)
        imports: Imports

# forward declaration
proc update(ctx: Context, t: float) {.cdecl.}

proc initialize(imports: Imports): Context {.cdecl, exportc, dynlib.} =
    # going to need to rethink actual import object as a lookup for procs,
    # rather than a raw struct, because we don't want this to be sensitive to
    # pointer layout, and also we want to be able to only use a subset of the
    # passed-in library
    result = cast[Context](imports.allocate(sizeof(ContextObj)))
    result.imports = imports
    result.update = update

# ---------------------------------
# hopefully can autogen above stuff

proc update(ctx: Context, t: float) {.cdecl.} =
    let pos = vec(120 + 10 * cos(5 * t), 200 + 100 * sin(t))
    ctx.imports.drawBox(ctx.imports, pos, vec(40, 40))

    ctx.imports.drawBox(ctx.imports, vec(300, 30), vec(40, 40))
