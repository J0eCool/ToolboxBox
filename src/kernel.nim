import sdl2

proc main() =
    discard sdl2.init(INIT_EVERYTHING)

    let (winW, winH) = (1200, 900)
    let window = createWindow("ToolboxBox", 100, 100, winW.cint, winH.cint, SDL_WINDOW_SHOWN)
    defer:
        destroy window
    let renderFlags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
    let render = createRenderer(window, -1, renderFlags)
    defer:
        destroy render

    var runGame = true
    var t = 0

    while runGame:
        var evt = sdl2.defaultEvent
        while pollEvent(evt):
            if evt.kind == QuitEvent:
                runGame = false
                break

        inc t
        t = t mod 256

        render.setDrawColor t.uint8,0,0,255
        render.clear
        render.present

echo "Helo werl"
main()
