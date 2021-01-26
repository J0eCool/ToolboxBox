import sdl2
import tables

import common
import ../vec

type
    Imports = object

    GraphicsModule* = ptr GraphicsModuleObj
    GraphicsModuleObj = object
        window*: WindowPtr
        render*: RendererPtr

var loadedModules: Table[Handle, GraphicsModule]
proc lookup(handle: Handle): GraphicsModule =
    result = loadedModules[handle]
    assert result != nil

proc drawBox*(graphics: GraphicsModule, pos, size: Vec)
proc wrap_drawBox(handle: Handle, pos, size: Vec) {.cdecl.} =
    drawBox(lookup(handle), pos, size)

proc initialize*(hnd: Handle, loader: Loader, imports: ptr Imports): GraphicsModule =
    result = cast[GraphicsModule](loader.allocate(hnd, sizeof(GraphicsModuleObj)))
    loadedModules[hnd] = result
    loader.register(hnd, "drawBox", wrap_drawBox)

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

proc drawBox*(graphics: GraphicsModule, pos, size: Vec) =
    var rec = rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)
    graphics.render.fillRect rec

