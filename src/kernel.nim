import dynlib
import math
import sdl2

type posFunc = proc(t: float): float {.gcsafe, stdcall.}

let lib = loadLib("testlib.dll")
assert lib != nil
let getPos = cast[posFunc](lib.symAddr("positionForTime"))

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

        let r = uint8(128 + 127 * sin(t * 3))
        render.setDrawColor r, 0, 0, 255
        render.clear

        render.setDrawColor 0, 255, 255, 255
        var rec = rect(20, 20, 80, 80)
        render.fillRect rec

        render.setDrawColor 128, 64, 255, 255
        let y = getPos(t).cint
        var rec2 = rect(120, y, 80, 80)
        render.fillRect rec2

        render.present

echo "Helo werl"
main()
