import dynlib
import math
import sdl2
import sdl2/[
    mixer,
    ttf,
]
import tables

import syscalls/[
    audio,
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
    let raw = alloc0(size + sizeof(pointer))
    return cast[pointer](cast[int](raw) + sizeof(Smeef))

proc register(smeef: Smeef, name: cstring, f: pointer) {.cdecl.} =
    collection.funcTable[smeef][$name] = f

func getSmeef(zarb: Zarb): Smeef =
    # oh this is cursed
    cast[ptr Smeef](cast[int](zarb) - sizeof(Smeef))[]

proc lookup(zarb: Zarb, name: cstring): pointer {.cdecl.} =
    let smeef = zarb.getSmeef()
    result = collection.funcTable[smeef][$name]

type
    initializeProc = proc(smeef: Smeef, loader: Loader) {.cdecl.}
    constructProc = proc(loader: Loader, imports: pointer): Zarb {.cdecl.}
    startProc = proc(module: Zarb) {.cdecl.}
    cleanupProc = proc(module: Zarb) {.cdecl.}

proc newSmeef(): Smeef =
    result = cast[Smeef](alloc(sizeof(SmeefObj)))
    collection.funcTable[result] = Table[string, pointer]()

proc loadSmeef(desc: SmeefDesc, loader: Loader): Smeef =
    let dll = loadLib(desc.dllFilename)
    assert dll != nil
    result = newSmeef()
    result.desc = desc
    result.dll = dll
    collection.funcTable[result] = Table[string, pointer]()
    let initialize = cast[initializeProc](dll.symAddr("initialize"))
    assert initialize != nil
    initialize(result, loader)

proc setSmeef(zarb: Zarb, smeef: Smeef) =
    # XXX: assumes construct calls `allocate` for its result, backfill smeef ptr (oh jeez)
    (cast[ptr Smeef](cast[int](zarb) - sizeof(Smeef)))[] = smeef

proc loadZarb(smeef: Smeef, loader: Loader, importSeq: seq[Zarb]): Zarb =
    var numImportedFuncs = 0
    for module in smeef.desc.imports:
        numImportedFuncs += module.len

    let numImports = importSeq.len + numImportedFuncs

    let imports = cast[ptr UncheckedArray[pointer]](alloc(importSeq.len * sizeof(pointer)))
    var importIdx = 0
    assert importSeq.len == smeef.desc.imports.len
    for i in 0..<importSeq.len:
        let zarb = importSeq[i]
        imports[importIdx] = zarb
        inc importIdx
        for fn in smeef.desc.imports[i]:
            imports[importIdx] = lookup(cast[Zarb](zarb), fn.cstring)
            inc importIdx

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
    discard mixer.init(MIX_INIT_OGG or MIX_INIT_MP3)

    # kernel tracking stuff
    let loader = cast[Loader](alloc(sizeof(LoaderObj)))
    loader.allocate = allocate
    loader.register = register
    loader.lookup = lookup

    # set up system modules
    let graphicsSmeef = newSmeef()
    graphicsSmeef.desc.name = "graphics"
    graphics.initialize(graphicsSmeef, loader)
    let graphics = graphics.construct(loader, nil)
    setSmeef(graphics, graphicsSmeef)
    graphics.start()
    defer: graphics.cleanup()

    let inputSmeef = newSmeef()
    inputSmeef.desc.name = "input"
    input.initialize(inputSmeef, loader)
    let input = input.construct(loader, nil)
    setSmeef(input, inputSmeef)
    input.start()
    defer: input.cleanup()

    let audioSmeef = newSmeef()
    audioSmeef.desc.name = "audio"
    audio.initialize(audioSmeef, loader)
    let audio = audio.construct(loader, nil)
    setSmeef(audio, audioSmeef)
    audio.start()
    defer: audio.cleanup()

    # now user modules
    let
        guiSmeefDesc = SmeefDesc(
            dllFilename: "gui.dll",
            name: "Gui",
            imports: @[
                @[
                    # graphics
                    "setRGB",
                    "drawBox",
                    "drawText",
                ], @[
                    # input
                    "mousePos",
                    "wasMouseReleased",
                ]
            ],
        )
        guiSmeef = loadSmeef(guiSmeefDesc, loader)
        gui = loadZarb(guiSmeef, loader, @[graphics, input])

    let
        testlibSmeefDesc = SmeefDesc(
            dllFilename: "testlib.dll",
            name: "TestLib",
            imports: @[
                @[
                    # graphics
                    "setRGB",
                    "drawBox",
                    "drawText",
                ], @[
                    # input
                    "isKeyHeld",
                    "wasKeyPressed",
                    "mousePos",
                    "wasMouseReleased",
                ], @[
                    # gui
                    "button",
                ]
            ],
        )
        testlibSmeef = loadSmeef(testlibSmeefDesc, loader)
        testlib = loadZarb(testlibSmeef, loader, @[graphics, input, gui])
        testlibUpdate = cast[proc(module: Handle, t: float) {.cdecl.}](lookup(testlib, "update"))

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

        let r = 168 + int(41 * sin(t * 3))
        graphics.setRGB(r, 0, 0)
        graphics.render.clear()

        graphics.setRGB(0, 255, 255)
        graphics.drawBox(vec(20, 20), vec(80, 80))

        testlibUpdate(testlib, t)

        graphics.render.present()

main()
