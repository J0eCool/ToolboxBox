run: out/kernel.exe out/testlib.dll
	out/kernel.exe
.PHONY: run

clean:
	rm -rf out/
.PHONY: clean

out/kernel.exe: src/kernel.nim src/syscalls/*
	nim c -o:out/kernel.exe src/kernel.nim

out/testlib.dll: src/testlib.nim
	nim c -o:out/testlib.dll --app:lib --gc:arc src/testlib.nim
