import dynlib
import math
import sdl2
import tables

import syscalls/[
    common,
    graphics,
    input,
]
import vec

type
    ModuleCollection = object
        nextHandleId: int
        privateData: Table[Handle, pointer]
        funcTable: Table[Handle, Table[string, pointer]]

    ModuleDesc = object
        funcs: Table[string, pointer]

    # test library
    Library = ptr object
        update: proc(lib: Library, t: float) {.cdecl.}

var collection = ModuleCollection()

proc newHandle(): Handle =
    result = Handle(collection.nextHandleId)
    inc collection.nextHandleId

proc allocate(handle: Handle, size: Natural): pointer {.cdecl.} =
    # might use the handle to do tracking of stuff later, heck
    result = alloc(size)
    collection.privateData[handle] = result
    collection.funcTable[handle] = Table[string, pointer]()

proc register(handle: Handle, name: cstring, f: pointer) {.cdecl.} =
    collection.funcTable[handle][$name] = f

proc lookup(handle: Handle, name: cstring): pointer {.cdecl.} =
    collection.funcTable[handle][$name]

proc drawBox(render: RendererPtr, pos, size: Vec) =
    var rec = rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)
    render.fillRect rec

proc drawWrapBox(handle: Handle, pos, size: Vec) {.cdecl.} =
    let module = cast[GraphicsModule](collection.privateData[handle])
    module.render.drawBox(pos, size)

proc main() =
    # set up sdl and window and such
    discard sdl2.init(INIT_EVERYTHING)

    # kernel tracking stuff
    let loader = cast[Loader](alloc(sizeof(LoaderObj)))
    loader.allocate = allocate
    loader.register = register
    loader.lookup = lookup

    # set up graphics module
    let graphicsHandle = newHandle()
    let graphics = graphics.initialize(graphicsHandle, loader, nil)
    graphics.start()
    defer: graphics.cleanup()
    loader.register(graphicsHandle, "drawBox", drawWrapBox)

    # do dll loady things
    let libDll = loadLib("testlib.dll")
    assert libDll != nil
    type initializeProc = proc(hnd: Handle, loader: Loader, imports: pointer): Library {.cdecl.}
    let libInit = cast[initializeProc](libDll.symAddr("initialize"))
    let libHandle = newHandle()
    let numImports = 2
    let libImports = cast[ptr UncheckedArray[Handle]](alloc(numImports * sizeof(Handle)))
    libImports[0] = graphicsHandle
    let module = libInit(libHandle, loader, libImports)
    dealloc(libImports)
    let moduleUpdate = cast[proc(module: Handle, t: float) {.cdecl.}](lookup(libHandle, "update"))

    # run loop, logic
    var runGame = true
    var t = 0.0

    while runGame:
        var evt = sdl2.defaultEvent
        while pollEvent(evt):
            case evt.kind
            of QuitEvent:
                runGame = false
                break
            of KeyDown:
                case evt.key.keysym.sym
                of K_ESCAPE:
                    runGame = false
                    break
                else:
                    discard
            else:
                discard

        t += 1.0 / 60.0

        let r = uint8(128 + 91 * sin(t * 3))
        graphics.render.setDrawColor r, 0, 0, 255
        graphics.render.clear

        graphics.render.setDrawColor 0, 255, 255, 255
        graphics.render.drawBox(vec(20, 20), vec(80, 80))

        graphics.render.setDrawColor 128, 64, 255, 255
        moduleUpdate(libHandle, t)

        graphics.render.present

echo "Helo werl"
main()
