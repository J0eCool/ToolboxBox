import sdl2
import sdl2/ttf

import common
import ../vec

type
    Imports = object

    GraphicsModule* = ptr GraphicsModuleObj
    GraphicsModuleObj = object of ZarbObj
        window*: WindowPtr
        render*: RendererPtr
        drawColor: Color
        font: FontPtr

# wrappers for public functions

proc setRGB*(graphics: GraphicsModule, r, g, b: int) {.cdecl.}
proc drawBox*(graphics: GraphicsModule, pos, size: Vec) {.cdecl.}
proc drawText*(graphics: GraphicsModule, pos: Vec, text: cstring) {.cdecl.}

# standard module hooks

proc initialize*(smeef: Smeef, loader: Loader) {.cdecl.} =
    loader.register(smeef, "setRGB", setRGB)
    loader.register(smeef, "drawBox", drawBox)
    loader.register(smeef, "drawText", drawText)

proc construct*(loader: Loader, imports: ptr Imports): GraphicsModule {.cdecl.} =
    result = cast[GraphicsModule](loader.allocate(sizeof(GraphicsModuleObj)))

proc start*(module: GraphicsModule) {.cdecl.} =
    let (winW, winH) = (1200, 900)
    module.window = createWindow("ToolboxBox",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        winW.cint, winH.cint, SDL_WINDOW_SHOWN)

    let renderFlags = (Renderer_Accelerated or Renderer_PresentVsync or
        Renderer_TargetTexture)
    module.render = createRenderer(module.window, -1, renderFlags)
    module.render.setDrawBlendMode(BlendMode_Blend)

    module.font = openFont("assets/Inconsolata-Regular.ttf", 24)

proc cleanup*(module: GraphicsModule) {.cdecl.} =
    module.font.close()
    module.render.destroy()
    module.window.destroy()

# exported functions

proc setRGB*(graphics: GraphicsModule, r, g, b: int) {.cdecl.} =
    let c = color(r, g, b, 255)
    graphics.drawColor = c
    assert graphics.render.setDrawColor(c.r, c.g, c.b, c.a)

proc drawBox*(graphics: GraphicsModule, pos, size: Vec) {.cdecl.} =
    var rec = rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)
    assert graphics.render.fillRect(rec)

proc drawText*(graphics: GraphicsModule, pos: Vec, text: cstring) {.cdecl.} =
    let surface: SurfacePtr = graphics.font.renderTextSolid(text, graphics.drawColor)
    let texture: TexturePtr = graphics.render.createTexture(surface)

    # src = nil means use default, which uses the whole texture
    var dest = rect(pos.x.cint, pos.y.cint, surface.w, surface.h)
    assert graphics.render.copy(texture, nil, addr dest)

    # cleanup
    surface.freeSurface()
    texture.destroyTexture()
