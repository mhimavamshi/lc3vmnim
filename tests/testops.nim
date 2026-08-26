import unittest 

import ../src/alltypes 
import ../src/ops

suite "ADD":
    setup: 
        var registers: Registers

    test "register mode":
        registers[R2] = 40
        registers[R3] = 50
        let instr = uint16(0b0001001010000011) # 1, 2, 3
        addOp(instr, registers)
        check registers[R1] == 90
        check registers[COND] == FL_POS

    test "immediate mode":
        registers[R1] = 40
        let instr = uint16(0b0001001001100101) # R1 = R1 + 5 
        addOp(instr, registers)
        check registers[R1] == 45
        check registers[COND] == FL_POS

    test "immediate mode sign extend":
        registers[R1] = 40
        let instr = uint16(0b0001001001111011) # R1 = R1 - 5
        addOp(instr, registers)
        check registers[R1] == 35
        check registers[COND] == FL_POS

suite "AND":
    setup:
        var registers: Registers

    test "register mode":
        registers[R2] = 0b1010
        registers[R3] = 0b1100
        let instr = uint16(0b0101001010000011) # AND R1, R2, R3
        andOp(instr, registers)
        check registers[R1] == 0b1000
        check registers[COND] == FL_POS

    test "immediate mode sign extend":
        registers[R2] = 0xFFFF
        let instr = uint16(0b0101001010111101) # AND R1, R2, #-3 (11101)
        andOp(instr, registers)
        check registers[R1] == 0xFFFD
        check registers[COND] == FL_NEG

suite "NOT":
    setup:
        var registers: Registers

    test "bitwise complement":
        registers[R2] = 0x00FF
        let instr = uint16(0b1001001010111111) # NOT R1, R2
        notOp(instr, registers)
        check registers[R1] == 0xFF00
        check registers[COND] == FL_NEG

suite "BR":
    setup:
        var registers: Registers

    test "branch taken when condition matches":
        registers[Register.PC] = 0x3000
        registers[Register.PC] += 1    # Simulate Fetch Phase Increment
        registers[Register.COND] = FL_NEG
        let instr = uint16(0b0000100000000101) # BRn #5
        br(instr, registers)
        check registers[Register.PC] == 0x3006 # 0x3001 + 5

    test "branch not taken when condition mismatches":
        registers[Register.PC] = 0x3000
        registers[Register.PC] += 1    # Simulate Fetch Phase Increment
        registers[Register.COND] = FL_POS
        let instr = uint16(0b0000100000000101) # BRn #5
        br(instr, registers)
        check registers[Register.PC] == 0x3001 # Remains unchanged from fetch step


suite "JMP and RET":
    setup:
        var registers: Registers

    test "JMP to register location":
        registers[PC] = 0x3000
        registers[R1] = 0x4500
        let instr = uint16(0b1100000001000000) # JMP R1
        jmp(instr, registers)
        check registers[PC] == 0x4500

    test "RET (JMP R7)":
        registers[PC] = 0x3000
        registers[R7] = 0x3500
        let instr = uint16(0b1100000111000000) # RET (JMP R7)
        jmp(instr, registers)
        check registers[PC] == 0x3500

suite "JSR and JSRR":
    setup:
        var registers: Registers

    test "JSR PC-relative":
        registers[Register.PC] = 0x3000
        registers[Register.PC] += 1    # Simulate Fetch Phase Increment
        let instr = uint16(0b0100100000000101) # JSR #5
        jsr(instr, registers)
        check registers[Register.R7] == 0x3001 # Saves the incremented PC
        check registers[Register.PC] == 0x3006 # 0x3001 + 5

    test "JSRR register mode":
        registers[Register.PC] = 0x3000
        registers[Register.PC] += 1    # Simulate Fetch Phase Increment
        registers[Register.R2] = 0x4000
        let instr = uint16(0b0100000010000000) # JSRR R2
        jsr(instr, registers)
        check registers[Register.R7] == 0x3001 # Saves the incremented PC
        check registers[Register.PC] == 0x4000

# suite "TRAP":
#     setup:
#         var registers: Registers

#     test "TRAP updates R7 and vector":
#         registers[PC] = 0x3000
#         let instr = uint16(0b1111000000100101) # TRAP x25 (HALT)
#         trapOp(instr, registers)
#         check registers[R7] == 0x3001

# suite "LOADS":
#     setup:
#         var registers: Registers
#         var memory: array[65536, uint16]

#     test "LD (PC-relative)":
#         registers[PC] = 0x3000
#         memory[0x3006] = 0xABCD          # 0x3001 + 5
#         let instr = uint16(0b0010001000000101) # LD R1, #5
#         ldOp(instr, registers, memory)
#         check registers[R1] == 0xABCD
#         check registers[COND] == FL_NEG

#     test "LDR (Base+Offset)":
#         registers[R2] = 0x4000
#         memory[0x4005] = 0x1234          # 0x4000 + 5
#         let instr = uint16(0b0110001010000101) # LDR R1, R2, #5
#         ldrOp(instr, registers, memory)
#         check registers[R1] == 0x1234
#         check registers[COND] == FL_POS

#     test "LDI (Indirect)":
#         registers[PC] = 0x3000
#         memory[0x3006] = 0x4000          # Target address table
#         memory[0x4000] = 0x7777          # Final data
#         let instr = uint16(0b1010001000000101) # LDI R1, #5
#         ldiOp(instr, registers, memory)
#         check registers[R1] == 0x7777
#         check registers[COND] == FL_POS

#     test "LEA (Load Effective Address)":
#         registers[PC] = 0x3000
#         let instr = uint16(0b1110001000000101) # LEA R1, #5
#         leaOp(instr, registers)
#         check registers[R1] == 0x3006 # Does not read memory, just computes address
#         check registers[COND] == FL_POS

# suite "STORES":
#     setup:
#         var registers: Registers
#         var memory: array[65536, uint16]

#     test "ST (PC-relative)":
#         registers[PC] = 0x3000
#         registers[R1] = 0x1111
#         let instr = uint16(0b0011001000000101) # ST R1, #5
#         stOp(instr, registers, memory)
#         check memory[0x3006] == 0x1111 # 0x3001 + 5

#     test "STR (Base+Offset)":
#         registers[R2] = 0x4000
#         registers[R1] = 0x2222
#         let instr = uint16(0b0111001010000101) # STR R1, R2, #5
#         strOp(instr, registers, memory)
#         check memory[0x4005] == 0x2222

#     test "STI (Indirect)":
#         registers[PC] = 0x3000
#         registers[R1] = 0x3333
#         memory[0x3006] = 0x4500          # Destination pointer
#         let instr = uint16(0b1011001000000101) # STI R1, #5
#         stiOp(instr, registers, memory)
#         check memory[0x4500] == 0x3333




