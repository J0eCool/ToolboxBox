import sdl2
import sdl2/ttf

import common
import ../vec

type
    Imports = object

    GraphicsModule* = ptr GraphicsModuleObj
    GraphicsModuleObj = object
        window*: WindowPtr
        render*: RendererPtr
        font: FontPtr

# wrappers for public functions

proc drawBox*(graphics: GraphicsModule, pos, size: Vec) {.cdecl.}
proc drawText*(graphics: GraphicsModule, pos: Vec, text: string) {.cdecl.}

# standard module hooks

proc initialize*(loader: Loader, imports: ptr Imports): GraphicsModule =
    result = cast[GraphicsModule](loader.allocate(sizeof(GraphicsModuleObj)))
    loader.register(result, "drawBox", drawBox)
    loader.register(result, "drawText", drawText)

proc start*(module: GraphicsModule) =
    let (winW, winH) = (1200, 900)
    module.window = createWindow("ToolboxBox",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        winW.cint, winH.cint, SDL_WINDOW_SHOWN)

    let renderFlags = (Renderer_Accelerated or Renderer_PresentVsync or
        Renderer_TargetTexture)
    module.render = createRenderer(module.window, -1, renderFlags)
    module.render.setDrawBlendMode(BlendMode_Blend)

    module.font = openFont("assets/Inconsolata-Regular.ttf", 24)

proc cleanup*(module: GraphicsModule) =
    module.font.close()
    module.render.destroy()
    module.window.destroy()

# exported functions

proc drawBox*(graphics: GraphicsModule, pos, size: Vec) {.cdecl.} =
    var rec = rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)
    assert graphics.render.fillRect(rec)

proc drawText*(graphics: GraphicsModule, pos: Vec, text: string) {.cdecl.} =
    let surface: SurfacePtr = graphics.font.renderTextSolid(text, color(255, 255, 255, 255))
    let texture: TexturePtr = graphics.render.createTexture(surface)

    # src = nil means use default, which uses the whole texture
    var dest = rect(pos.x.cint, pos.y.cint, surface.w, surface.h)
    assert graphics.render.copy(texture, nil, addr dest)

    # cleanup
    surface.freeSurface()
    texture.destroyTexture()
