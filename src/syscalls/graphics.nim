import sdl2

import common

type
    Imports = object

    GraphicsModule* = ptr GraphicsModuleObj
    GraphicsModuleObj = object
        window*: WindowPtr
        render*: RendererPtr

proc initialize*(hnd: Handle, loader: Loader, imports: ptr Imports): GraphicsModule =
    result = cast[GraphicsModule](loader.allocate(hnd, sizeof(GraphicsModuleObj)))

proc start*(module: GraphicsModule) =
    let (winW, winH) = (1200, 900)
    module.window = createWindow("ToolboxBox",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        winW.cint, winH.cint, SDL_WINDOW_SHOWN)

    let renderFlags = (Renderer_Accelerated or Renderer_PresentVsync or
        Renderer_TargetTexture)
    module.render = createRenderer(module.window, -1, renderFlags)

proc cleanup*(module: GraphicsModule) =
    destroy module.window
    destroy module.render
