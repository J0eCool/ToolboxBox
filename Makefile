run: out/kernel.exe out/SDL2.dll out/testlib.dll out/gui.dll
	out/kernel.exe
.PHONY: run

clean:
	rm -rf out/
.PHONY: clean

DEBUG=
# DEBUG=--debugger:native

out/SDL2.dll: assets/sdl_dlls/SDL2.dll
	cp  assets/sdl_dlls/* out/

out/kernel.exe: src/kernel.nim nim.cfg src/kernel.nim.cfg src/syscalls/*
	nim c $(DEBUG) -o:out/kernel.exe src/kernel.nim

out/testlib.dll: src/testlib.nim nim.cfg
	nim c $(DEBUG) -o:out/testlib.dll --app:lib --gc:arc src/testlib.nim
out/gui.dll: src/gui.nim nim.cfg
	nim c $(DEBUG) -o:out/gui.dll --app:lib --gc:arc src/gui.nim
