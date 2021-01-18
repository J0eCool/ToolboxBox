run: out/kernel.exe out/testlib.dll
	out/kernel.exe
.PHONY: run

out/kernel.exe: src/kernel.nim
	nim c -o:out/kernel.exe src/kernel.nim

out/testlib.dll: src/testlib.nim
	nim c -o:out/testlib.dll --app:lib --gc:arc src/testlib.nim