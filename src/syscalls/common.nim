type
    Handle* = pointer

    # module modeling kernel loader code
    Loader* = ptr LoaderObj
    LoaderObj* = object
        allocate*: proc(t: Natural): pointer {.cdecl.}
        register*: proc(module: Handle, name: cstring, f: pointer) {.cdecl.}
        lookup*: proc(hnd: Handle, name: cstring): pointer {.cdecl.}
