import math
import sdl2/[
    audio,
    mixer,
]

import common

type
    Imports = object

    AudioModule* = ptr AudioModuleObj
    AudioModuleObj = object of ZarbObj

# wrappers for public functions

#[ this space intentionally left blank ]#

# not totally sure where to put this just yet; give it time
var audioTime = 0
proc audioHook(udata: pointer, rawstream: ptr uint8, size: cint) {.cdecl.} =
    let stream = cast[ptr UncheckedArray[int16]](rawstream)
    let count = size div 2 # bytes -> samples
    let volume = 0.5
    for i in 0..<count:
        stream[i] = int16(volume * 256 * 256 * sin(440.0 / 22050.0 * (i + audioTime).float))
    audioTime += count

# standard module hooks

proc initialize*(smeef: Smeef, loader: Loader) {.cdecl.} =
    discard

proc construct*(loader: Loader, imports: ptr Imports): AudioModule {.cdecl.} =
    result = cast[AudioModule](loader.allocate(sizeof(AudioModuleObj)))

proc start*(module: AudioModule) {.cdecl.} =
    let
        audioFrequency: cint = 22050 # Hz
        audioFormat: uint16 = AUDIO_S16 # 16bit audio; assuming Little-Endian
        audioChannels: cint = 1 # mono
        audioChunksize: cint = 512
    assert mixer.openAudio(audioFrequency, audioFormat, audioChannels, audioChunksize) == 0
    hookMusic(audioHook, nil)

proc cleanup*(module: AudioModule) {.cdecl.} =
    # hookMusic(nil, nil) # to stop music
    mixer.closeAudio()

# exported functions

#[ this space intentionally left blank ]#
