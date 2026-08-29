import std/unittest
import std/streams
import std/os

import ../src/alltypes
import ../src/utils
import ../src/lc3vmnim

suite "readImageFile":

  test "loads image into memory":
    let filename = "test_image.obj"

    let f = newFileStream(filename, fmWrite)

    f.write(swap16(0x3000'u16))
    f.write(swap16(0x1234'u16))
    f.write(swap16(0xABCD'u16))

    f.close()

    var memory: Memory

    # Put sentinels around the expected image location.
    memory[0x2FFF] = 0xAAAA
    memory[0x3002] = 0xBBBB

    readImageFile(filename, memory)

    check:
      memory[0x2FFF] == 0xAAAA
      memory[0x3000] == 0x1234
      memory[0x3001] == 0xABCD
      memory[0x3002] == 0xBBBB

    removeFile(filename)