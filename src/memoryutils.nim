import alltypes
import inpbuffer

#[
I guess, instead of doing it this way - the way of tutorial, reading on memory register access 
you can, in the main loop do select poll over input, instead of at the memory access
and also have ready bit as part of the data/keyboard state
if its ready, which is set if a character is typed, we disable the keyboard input
if we read the KBDR, we set the ready to 0, and keyboard is enabled
this simulates the real world async keyboard i guess
]#
proc memRead*(address: uint16, memory: var Memory): uint16 = 
  if address == MR_KBSR:
    if check_key(): 
      memory[MR_KBSR] = (1 shl 15)
      memory[MR_KBDR] = uint16(stdin.readChar()) 
    else:
      memory[MR_KBSR] = 0
  return memory[address]

proc memWrite*(address: uint16, value: uint16, memory: var Memory) =
  memory[address] = value
