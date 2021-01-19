import dynlib
import math
import sdl2

import vec

type
    posFunc = proc(t: float): Vec {.cdecl.}
    updateFunc = proc(t: float, callback: proc(pos: Vec) {.cdecl.}) {.cdecl.}

let lib = loadLib("testlib.dll")
assert lib != nil
let getPos = cast[posFunc](lib.symAddr("positionForTime"))
let wrapUpdate = cast[updateFunc](lib.symAddr("update"))

var globalRenderer: RendererPtr

proc drawBox(render: RendererPtr, pos, size: Vec) =
    var rec = rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)
    render.fillRect rec

proc drawWrapBox(pos: Vec) {.cdecl.} =
    globalRenderer.drawBox(pos, vec(40, 40))

proc main() =
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
    globalRenderer = render
    defer:
        destroy render

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
        let pos = getPos(t)
        render.drawBox(pos, vec(80, 80))

        render.setDrawColor 0, 0, 0, 255
        wrapUpdate(t, drawWrapBox)

        render.present

echo "Helo werl"
main()
