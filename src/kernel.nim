import dynlib
import math
import sdl2
import sdl2/ttf
import tables

import syscalls/[
    common,
    graphics,
    input,
]
import vec

type
    ModuleCollection = object
        # table of function pointers
        # TODO: make this per-dll, not per-instance
        funcTable: Table[Handle, Table[string, pointer]]

    ModuleDesc = object
        funcs: Table[string, pointer]

var collection = ModuleCollection()

proc allocate(size: Natural): pointer {.cdecl.} =
    # might use the handle to do tracking of stuff later, heck
    result = alloc(size)
    collection.funcTable[result.Handle] = Table[string, pointer]()

proc register(handle: Handle, name: cstring, f: pointer) {.cdecl.} =
    collection.funcTable[handle][$name] = f

proc lookup(handle: Handle, name: cstring): pointer {.cdecl.} =
    collection.funcTable[handle][$name]

type
    initializeProc = proc(loader: Loader, imports: pointer): Handle {.cdecl.}
    startProc = proc(module: Handle) {.cdecl.}
    cleanupProc = proc(module: Handle) {.cdecl.}

proc loadModule(filename: string, loader: Loader, importSeq: seq[pointer]): Handle =
    let dll = loadLib("testlib.dll")
    assert dll != nil
    let initialize = cast[initializeProc](dll.symAddr("initialize"))
    let start = cast[startProc](dll.symAddr("start"))
    let imports = cast[ptr UncheckedArray[pointer]](alloc(importSeq.len * sizeof(pointer)))
    for i in 0..<importSeq.len:
        imports[i] = importSeq[i]
    result = initialize(loader, imports)
    dealloc(imports)
    if start != nil:
        start(result)

proc main() =
    # set up sdl and window and such
    assert sdl2.init(INIT_EVERYTHING)
    assert ttfInit()

    # kernel tracking stuff
    let loader = cast[Loader](alloc(sizeof(LoaderObj)))
    loader.allocate = allocate
    loader.register = register
    loader.lookup = lookup

    # set up system modules
    let graphics = graphics.initialize(loader, nil)
    graphics.start()
    defer: graphics.cleanup()

    let input = input.initialize(loader, nil)
    input.start()
    defer: input.cleanup()

    # now user modules
    let module = loadModule("testlib.dll", loader, @[graphics.pointer, input.pointer])
    let moduleUpdate = cast[proc(module: Handle, t: float) {.cdecl.}](lookup(module, "update"))

    # run loop, logic
    var runGame = true
    var t = 0.0

    while runGame:
        input.update()
        var evt = sdl2.defaultEvent
        while pollEvent(evt):
            case evt.kind
            of QuitEvent:
                runGame = false
                break
            of KeyDown:
                if evt.key.keysym.sym == K_ESCAPE:
                    runGame = false
                    break
                input.onKeyDown(evt.key.keysym.sym)
            of KeyUp:
                input.onKeyUp(evt.key.keysym.sym)
            of MouseMotion:
                input.onMouseMotion(evt.motion.x, evt.motion.y)
            of MouseButtonDown:
                input.onMouseDown(evt.button.button.int)
            of MouseButtonUp:
                input.onMouseUp(evt.button.button.int)
            else:
                discard

        t += 1.0 / 60.0

        let r = uint8(168 + 41 * sin(t * 3))
        assert graphics.render.setDrawColor(r, 0, 0, 255)
        graphics.render.clear()

        assert graphics.render.setDrawColor(0, 255, 255, 255)
        graphics.drawBox(vec(20, 20), vec(80, 80))

        assert graphics.render.setDrawColor(128, 64, 255, 255)
        moduleUpdate(module, t)

        graphics.render.present()

main()
