import dynlib

type
    Handle* = pointer

    # module modeling kernel loader code
    Loader* = ptr LoaderObj
    LoaderObj* = object
        allocate*: proc(t: Natural): pointer {.cdecl.}
        register*: proc(module: Smeef, name: cstring, f: pointer) {.cdecl.}
        lookup*: proc(hnd: Zarb, name: cstring): pointer {.cdecl.}

    # A Smeef is the static data associated with a given .dll file
    Smeef* = ptr SmeefObj
    SmeefObj* = object
        desc*: SmeefDesc
        dll*: LibHandle

    # IDL description of a Smeef
    SmeefDesc* = object
        # SmeefDesc will likely be read from a .idl file, with a ref to .dll
        dllFilename*: string
        name*: string
        imports*: seq[seq[string]]

    # A Zarb is a runtime-instantiated Smeef
    Zarb* = ptr ZarbObj
    ZarbObj* = object of RootObj
