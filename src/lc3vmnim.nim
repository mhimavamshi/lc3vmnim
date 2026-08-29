import alltypes
import memoryutils
import ops
import std/streams
import utils 

#[ 
there's an alternative way to write this, instead of 1->1 w c 
we can also, maybe, read the whole file once and then 
]#
proc readImageFile*(name: string, memory: var Memory) = 
  let MEMORYMAX = 65535'u16

  let f = newFileStream(name, fmRead)
  if not f.isNil:
    defer: f.close()
    let origin = swap16(f.readUint16())

    let maxRead = int(MEMORYMAX - origin + 1)

    var read = f.readData(addr memory[origin], maxRead * sizeof(uint16))
    let wordsRead = read div sizeof(uint16)

    for i in 0..<wordsRead:
      let offset = uint16(i)
      memory[origin + offset] = swap16(memory[origin + offset])



proc main() =
  # 2^16 locations (16 bit unsigned integer), and each has 16 bit value
  var memory: Memory

  # 10 registers, each 16 bits - 8 general purpose, 1 PC, 1 COND flag
  # const REGISTERSMAX = 10
  var registers: Registers
  
  registers[Register.COND] = FL_ZRO

  const START = 12288
  registers[Register.PC] = START 

  var running = Running(true)

  while bool(running):
    let instr = memRead(registers[Register.PC])
    registers[Register.PC] += 1
    
    let op = instr shr 12 # get the first 4 bits from 16 bit word which is the opcode 
    let code = Opcodes(op)

    case code:
      of ADD:
        addOp(instr, registers)
      of AND:
        andOp(instr, registers)
      of NOT:
        notOp(instr, registers)
      of BR:
        br(instr, registers)                                                    
      of JMP:
        jmp(instr, registers)
      of JSR:
        jsr(instr, registers)
      of LD:
        ld(instr, registers)
      of LDI:
        ldi(instr, registers)
      of LDR:
        ldr(instr, registers)
      of LEA:
        lea(instr, registers)
      of ST:
        st(instr, registers)
      of STI:
        sti(instr, registers)
      of STR:
        str(instr, registers)
      of TRAP:
        trap(instr, registers, memory, running)
      of RES, RTI:
        badOpcode()

when isMainModule:
  main()
