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
        # number of samples processed
        time: int
        # 0 to 1
        volume: float
        # overall sampling frequency
        frequency: int
        # bytes to buffer at once
        chunkSize: int

proc audioCallback(udata: pointer, rawstream: ptr uint8, size: cint) {.cdecl.} =
    let
        module = cast[AudioModule](udata)
        stream = cast[ptr UncheckedArray[int16]](rawstream)
        count = size div 2 # bytes -> samples
        maxVolume = 1 shl 15 - 1
        vol = module.volume * maxVolume.float
    for i in 0..<count:
        let
            t = float(i + module.time)
            sample = sin(440.0 / module.frequency.float * t)
        stream[i] = int16(vol * sample)
    module.time += count

# wrappers for public functions

#[ this space intentionally left blank ]#

# standard module hooks

proc initialize*(smeef: Smeef, loader: Loader) {.cdecl.} =
    discard

proc construct*(loader: Loader, imports: ptr Imports): AudioModule {.cdecl.} =
    result = cast[AudioModule](loader.allocate(sizeof(AudioModuleObj)))
    result.time = 0
    result.volume = 0.75
    result.frequency = 22050
    result.chunkSize = 512

proc start*(module: AudioModule) {.cdecl.} =
    let
        audioFormat: uint16 = AUDIO_S16 # 16bit audio; assuming Little-Endian
        audioChannels: cint = 1 # mono
    assert mixer.openAudio(module.frequency.cint, audioFormat, audioChannels, module.chunkSize.cint) == 0
    hookMusic(audioCallback, module)

proc cleanup*(module: AudioModule) {.cdecl.} =
    # hookMusic(nil, nil) # to stop music
    mixer.closeAudio()

# exported functions

# proc beep*(module: AudioModule, tone, duration: float) {.cdecl.} =
