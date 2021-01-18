import sdl2

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
    var t = 0

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

        inc t

        render.setDrawColor t.uint8, 0, 0, 255
        render.clear

        render.setDrawColor 0, 255, 255, 255
        var r = rect(20, 20, 80, 80)
        render.fillRect r

        render.present

echo "Helo wrerl"
main()
