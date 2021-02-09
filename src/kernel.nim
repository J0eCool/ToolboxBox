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
        funcTable: Table[Smeef, Table[string, pointer]]

var collection = ModuleCollection()

proc allocate(size: Natural): pointer {.cdecl.} =
    # leave space before the allocation to store a Smeef pointer
    # XXX: said pointer is not filled until after `construct` returns :[
    let raw = alloc(size + sizeof(pointer))
    return cast[pointer](cast[int](raw) + sizeof(Smeef))

proc register(handle: Smeef, name: cstring, f: pointer) {.cdecl.} =
    collection.funcTable[handle][$name] = f

proc lookup(handle: Zarb, name: cstring): pointer {.cdecl.} =
    # oh this is cursed
    let index = cast[ptr Smeef](cast[int](handle) - sizeof(Smeef))[]
    collection.funcTable[index][$name]

type
    initializeProc = proc(smeef: Smeef, loader: Loader) {.cdecl.}
    constructProc = proc(loader: Loader, imports: pointer): Zarb {.cdecl.}
    startProc = proc(module: Zarb) {.cdecl.}
    cleanupProc = proc(module: Zarb) {.cdecl.}

proc newSmeef(): Smeef =
    result = cast[Smeef](alloc(sizeof(SmeefObj)))
    collection.funcTable[result] = Table[string, pointer]()

proc loadSmeef(filename: string, loader: Loader): Smeef =
    let dll = loadLib(filename)
    assert dll != nil
    result = newSmeef()
    result.dll = dll
    collection.funcTable[result] = Table[string, pointer]()
    let initialize = cast[initializeProc](dll.symAddr("initialize"))
    assert initialize != nil
    initialize(result, loader)

proc setSmeef(zarb: Zarb, smeef: Smeef) =
    # XXX: assumes construct calls `allocate` for its result, backfill smeef ptr (oh jeez)
    (cast[ptr Smeef](cast[int](zarb) - sizeof(Smeef)))[] = smeef

proc loadZarb(smeef: Smeef, loader: Loader, importSeq: seq[pointer]): Zarb =
    let imports = cast[ptr UncheckedArray[pointer]](alloc(importSeq.len * sizeof(pointer)))
    for i in 0..<importSeq.len:
        imports[i] = importSeq[i]
    let construct = cast[constructProc](smeef.dll.symAddr("construct"))
    assert construct != nil
    result = construct(loader, imports)
    setSmeef(result, smeef)
    dealloc(imports)
    let start = cast[startProc](smeef.dll.symAddr("start"))
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
    let graphicsSmeef = newSmeef()
    graphics.initialize(graphicsSmeef, loader)
    let graphics = graphics.construct(loader, nil)
    setSmeef(graphics, graphicsSmeef)
    graphics.start()
    defer: graphics.cleanup()

    let inputSmeef = newSmeef()
    input.initialize(inputSmeef, loader)
    let input = input.construct(loader, nil)
    setSmeef(input, inputSmeef)
    input.start()
    defer: input.cleanup()

    # now user modules
    let testlibSmeef = loadSmeef("testlib.dll", loader)
    let testlib = loadZarb(testlibSmeef, loader, @[graphics.pointer, input.pointer])
    let testlibUpdate = cast[proc(module: Handle, t: float) {.cdecl.}](lookup(testlib, "update"))

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
        testlibUpdate(testlib, t)

        graphics.render.present()

main()
