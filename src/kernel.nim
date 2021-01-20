import dynlib
import math
import sdl2

import vec

type
    Context = ptr ContextObj
    ContextObj = object
        allocate: proc(t: Natural): pointer {.cdecl.}
        drawBox: proc(ctx: Context, pos, size: Vec) {.cdecl.}
        # private-ish var
        render: RendererPtr

    Library = ptr object
        update: proc(lib: Library, t: float) {.cdecl.}

proc allocate(size: Natural): pointer {.cdecl.} =
    alloc(size)

proc drawBox(render: RendererPtr, pos, size: Vec) =
    var rec = rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)
    render.fillRect rec

proc drawWrapBox(ctx: Context, pos, size: Vec) {.cdecl.} =
    ctx.render.drawBox(pos, size)

proc initialize(render: RendererPtr): Context =
    result = cast[Context](allocate(sizeof(ContextObj)))
    result.allocate = allocate
    result.drawBox = drawWrapBox
    result.render = render

proc main() =
    # set up sdl and window and such
    discard sdl2.init(INIT_EVERYTHING)

    let (winW, winH) = (1200, 900)
    let window = createWindow("ToolboxBox",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        winW.cint, winH.cint, SDL_WINDOW_SHOWN)
    defer:
        destroy window

    let renderFlags = (Renderer_Accelerated or Renderer_PresentVsync or
        Renderer_TargetTexture)
    let render = createRenderer(window, -1, renderFlags)
    defer:
        destroy render

    # set up self module
    let ctx = initialize(render)

    # do dll loady things
    let libDll = loadLib("testlib.dll")
    assert libDll != nil
    let libInit = cast[proc(ctx: Context): Library {.cdecl.}](libDll.symAddr("initialize"))
    let module = libInit(ctx)

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
        render.setDrawColor r, 0, 0, 255
        render.clear

        render.setDrawColor 0, 255, 255, 255
        render.drawBox(vec(20, 20), vec(80, 80))

        render.setDrawColor 128, 64, 255, 255
        module.update(module, t)

        render.present

echo "Helo werl"
main()
