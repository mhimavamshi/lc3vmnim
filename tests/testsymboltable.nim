import unittest

import ../src/lc3as
import std/strutils
import std/tables
import std/enumerate
import ../src/alltypes


proc makeNodes(source: string): seq[LineNode] =
  for (i, text) in enumerate(source.splitLines()):
    let clean = text.strip()

    if clean.len == 0:
      continue

    var line = new(Line)
    line.number = i + 1
    line.text = clean

    result.add(classifyLine(line))


suite "Symbol Table":

  test "label points to current address":
    let nodes = makeNodes("""
      .ORIG 12288
      START
      .END
    """)

    let symbols = makeSymbolTable(nodes)

    check symbols["START"] == 12288'u16


  test "label accounts for instruction size":
    let nodes = makeNodes("""
      .ORIG 12288
      ADD R1, R2, R3
      NEXT
      .END
    """)

    let symbols = makeSymbolTable(nodes)

    check symbols["NEXT"] == 12289'u16


  test "label body contributes to address":
    let nodes = makeNodes("""
      .ORIG 12288
      START ADD R1, R2, R3
      NEXT
      .END
    """)

    let symbols = makeSymbolTable(nodes)

    check symbols["START"] == 12288'u16
    check symbols["NEXT"] == 12289'u16


  test "FILL consumes one word":
    let nodes = makeNodes("""
      .ORIG 12288
      .FILL 10
      VALUE
      .END
    """)

    let symbols = makeSymbolTable(nodes)

    check symbols["VALUE"] == 12289'u16


  test "BLKW consumes requested number of words":
    let nodes = makeNodes("""
      .ORIG 12288
      .BLKW 3
      NEXT
      .END
    """)

    let symbols = makeSymbolTable(nodes)

    check symbols["NEXT"] == 12291'u16


  test "STRINGZ includes null terminator":
    let nodes = makeNodes("""
      .ORIG 12288
      .STRINGZ "hi"
      NEXT
      .END
    """)

    let symbols = makeSymbolTable(nodes)

    check symbols["NEXT"] == 12291'u16


  test "label-only lines consume no memory":
    let nodes = makeNodes("""
      .ORIG 12288
      A
      B
      .END
    """)

    let symbols = makeSymbolTable(nodes)

    check symbols["A"] == 12288'u16
    check symbols["B"] == 12288'u16


  test "multiple ORIG statements reset address":
    let nodes = makeNodes("""
      .ORIG 12288
      A ADD R1, R2, R3
      .ORIG 16384
      B
      .END
    """)

    let symbols = makeSymbolTable(nodes)

    check symbols["A"] == 12288'u16
    check symbols["B"] == 16384'u16


  test "missing ORIG raises error":
    let nodes = makeNodes("""
      START
      .END
    """)

    expect FirstPassError:
      discard makeSymbolTable(nodes)


  test "missing END raises error":
    let nodes = makeNodes("""
      .ORIG 12288
      START
    """)

    expect FirstPassError:
      discard makeSymbolTable(nodes)


  test "END before ORIG raises error":
    let nodes = makeNodes("""
      .END
      .ORIG 12288
    """)

    expect FirstPassError:
      discard makeSymbolTable(nodes)


  test "multiple END statements raise error":
    let nodes = makeNodes("""
      .ORIG 12288
      .END
      .END
    """)

    expect FirstPassError:
      discard makeSymbolTable(nodes)