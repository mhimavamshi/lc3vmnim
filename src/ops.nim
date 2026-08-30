import alltypes
import utils
import memoryutils

proc addOp*(instr: uint16, registers: var Registers) =
    # destination register - and with 0000111 
    let r0 = Register((instr shr 9) and 7'u16)
    # first operand - and with 0000111 
    let r1 = Register((instr shr 6) and 7'u16)
    # immediate mode flag
    let immFlag = (instr shr 5) and 1'u16

    if immFlag == 1:
        let imm5 = signExtend(instr and 0x1F'u16, 5)
        registers[r0] = registers[r1] + imm5
    else:
        let r2 = Register(instr and 7'u16)
        registers[r0] = registers[r1] + registers[r2]
    
    updateFlags(r0, registers)


proc ldi*(instr: uint16, registers: var Registers, memory: var Memory) = 
    # destination register
    let r0 = Register((instr shr 9) and 7'u16)
    # PC offset 
    let pcOffset = signExtend(instr and 0x1FF'u16, 9)
    # add the offset to PC, look at that memory location, get the value inside
    # that value is another address, so fetch from memory again
    registers[r0] = memRead(memRead(registers[Register.PC] + pcOffset, memory), memory)
    updateFlags(r0, registers)

proc andOp*(instr: uint16, registers: var Registers) = 
    # destination register 
    let r0 = Register((instr shr 9) and 7'u16)
    # source register
    let r1 = Register((instr shr 6) and 7'u16)

    let immFlag = (instr shr 5) and 1'u16

    if immFlag == 1:
        let imm5 = signExtend(instr and 0x1F'u16, 5)
        registers[r0] = registers[r1] and imm5 
    else:
        let r2 = Register(instr and 7'u16)
        registers[r0] = registers[r1] and registers[r2]

    updateFlags(r0, registers)

proc notOp*(instr: uint16, registers: var Registers) = 
    let r0 = Register((instr shr 9) and 7'u16)
    let r1 = Register((instr shr 6) and 7'u16)

    registers[r0] = not registers[r1]
    updateFlags(r0, registers)

proc br*(instr: uint16, registers: var Registers) =
    let condFlag = (instr shr 9) and 7'u16
    if (condFlag and registers[Register.COND]) != 0:
        let pcOffset = signExtend(instr and 0x1FF'u16, 9)
        registers[Register.PC] += pcOffset

proc jmp*(instr: uint16, registers: var Registers) =
    let r1 = Register((instr shr 6) and 7'u16)
    registers[Register.PC] = registers[r1]
    
proc jsr*(instr: uint16, registers: var Registers) =
    let longFlag = (instr shr 11) and 1'u16 
    registers[Register.R7] = registers[Register.PC]

    if (longFlag == 1):
        let longPcOffset = signExtend(instr and 0x7FF'u16, 11) 
        registers[Register.PC] += longPcOffset
    else:
        let r1 = Register((instr shr 6) and 7'u16)
        registers[Register.PC] = registers[r1]

proc ld*(instr: uint16, registers: var Registers, memory: var Memory) =
    let r0 = Register((instr shr 9) and 7'u16) 
    let pcOffset = signExtend(instr and 0x1FF'u16, 9)
    registers[r0] = memRead(registers[Register.PC] + pcOffset, memory)
    updateFlags(r0, registers)

proc ldr*(instr: uint16, registers: var Registers, memory: var Memory) =
    let r0 = Register((instr shr 9) and 7'u16) 
    let r1 = Register((instr shr 6) and 7'u16)
    let offset = signExtend(instr and 0x3F'u16, 6)
    registers[r0] = memRead(registers[r1] + offset, memory)
    updateFlags(r0, registers)

proc lea*(instr: uint16, registers: var Registers) =
    let r0 = Register((instr shr 9) and 7'u16) 
    let pcOffset = signExtend(instr and 0x1FF, 9)
    registers[r0] = registers[Register.PC] + pcOffset
    updateFlags(r0, registers)

proc st*(instr: uint16, registers: var Registers, memory: var Memory) =
    let r0 = Register((instr shr 9) and 7'u16)
    let pcOffset = signExtend(instr and 0x1FF'u16, 9)
    memWrite(registers[Register.PC] + pcOffset, registers[r0], memory)

proc sti*(instr: uint16, registers: var Registers, memory: var Memory) =
    let r0 = Register((instr shr 9) and 7'u16)
    let pcOffset = signExtend(instr and 0x1FF'u16, 9)
    memWrite(memRead(registers[Register.PC] + pcOffset, memory), registers[r0], memory)

proc str*(instr: uint16, registers: var Registers, memory: var Memory) =
    let r0 = Register((instr shr 9) and 7'u16)
    let r1 = Register((instr shr 6) and 7'u16)
    let offset = signExtend(instr and 0x3F'u16, 6)
    memWrite(registers[r1] + offset, registers[r0], memory)

proc trapPuts(registers: var Registers, memory: Memory) =
    var n = registers[Register.R0]

    while memory[n] != 0:
        stdout.write(char(memory[n]))
        n += 1

    stdout.flushFile()

proc trapGetC(registers: var Registers) =
    let c = stdin.readChar()
    registers[Register.R0] = uint16(ord(c))
    updateFlags(Register.R0, registers)

proc trapOut(registers: var Registers) = 
    stdout.write(char(registers[Register.R0])) 
    stdout.flushFile()

proc trapIn(registers: var Registers) = 
    stdout.write("Enter a character: ")
    let c = stdin.readChar()
    stdout.write(c)
    stdout.flushFile()
    registers[Register.R0] = uint16(c)
    updateFlags(Register.R0, registers)

proc trapPutsp(registers: var Registers, memory: Memory) = 
    var n = registers[Register.R0]
    while (memory[n] != 0):
        let c1 = char(memory[n] and 0xFF'u16) 
        stdout.write(c1)
        let r2 = memory[n] shr 8
        if r2 != 0:
            stdout.write(char(r2))
        n += 1
    stdout.flushFile()

proc trapHalt(running: var Running) = 
    stdout.write("HALT")
    stdout.flushFile()
    running = Running(false)

#[
well apparently, you take the instruction, get the vector address which is in the beginning of the code/data
save the PC to register
jump and execute from there
and then return back
but here we just switch
]#
proc trap*(instr: uint16, registers: var Registers, memory: Memory, running: var Running) =
    registers[Register.R7] = registers[Register.PC]

    case TrapCode(instr and 0xFF'u16):
        of GETC:
            trapGetC(registers)
        of OUT:
            trapOut(registers)
        of PUTS:
            trapPuts(registers, memory)
        of IN:
            trapIn(registers)
        of PUTSP:
            trapPutsp(registers, memory)
        of HALT:
            trapHalt(running)

proc badOpcode*() = 
    discard 
