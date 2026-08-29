import alltypes

proc swap16*(x: uint16): uint16 {.inline.} = 
  (x shl 8) or (x shr 8)

proc signExtend*(x: uint16, bit_count: int): uint16 = 
  result = x 
  if ((x shr (bit_count - 1)) and 1'u16) == 1'u16:
    result = result or uint16(0xFFFF'u16 shl bit_count)

proc updateFlags*(r: Register, registers: var Registers) =
  if registers[r] == 0:
    registers[Register.COND] = FL_ZRO
  elif (registers[r] shr 15) == 1:
    registers[Register.COND] = FL_NEG
  else:
    registers[Register.COND] = FL_POS                                    