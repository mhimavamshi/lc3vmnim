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


    test "BRz branches when condition is zero":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_ZRO

        # BRz +1
        br(0x0401'u16, registers)

        check registers[Register.PC] == 0x3001

    test "BRz does not branch when condition is positive":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_POS

        # BRz +1
        br(0x0401'u16, registers)

        check registers[Register.PC] == 0x3000

    test "BRn branches when condition is negative":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_NEG

        # BRn +1
        br(0x0801'u16, registers)

        check registers[Register.PC] == 0x3001

    test "BRnz branches for zero":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_ZRO

        # BRnz +1
        br(0x0C01'u16, registers)

        check registers[Register.PC] == 0x3001

    test "BRnz branches for negative":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_NEG

        # BRnz +1
        br(0x0C01'u16, registers)

        check registers[Register.PC] == 0x3001

    test "BRnz does not branch for positive":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_POS

        # BRnz +1
        br(0x0C01'u16, registers)

        check registers[Register.PC] == 0x3000

    test "BRnzp branches for positive":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_POS

        # BRnzp +1
        br(0x0E01'u16, registers)

        check registers[Register.PC] == 0x3001

    test "BRnzp branches for zero":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_ZRO

        # BRnzp +1
        br(0x0E01'u16, registers)

        check registers[Register.PC] == 0x3001

    test "BRnzp branches for negative":
        registers[Register.PC] = 0x3000
        registers[Register.COND] = FL_NEG

        # BRnzp +1
        br(0x0E01'u16, registers)

        check registers[Register.PC] == 0x3001


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


suite "TRAP":

    setup:
        var registers: Registers
        var memory: Memory
        var running = Running(true)

    test "TRAP updates R7":
        registers[PC] = 0x3001

        let instr = uint16(0b1111000000100101)

        trap(instr, registers, memory, running)

        check registers[R7] == 0x3001

    test "HALT stops VM":
        let instr = uint16(0b1111000000100101)

        trap(instr, registers, memory, running)

        check bool(running) == false


suite "LOADS - Negative Offsets":

    setup:
        var registers: Registers
        var memory: Memory

    test "LD (negative PC-relative)":
        registers[PC] = 0x3001
        memory[0x2FFD] = 0xABCD  # 0x3001 - 4

        let instr = uint16(0b0010001111111100) # LD R1, #-4

        ld(instr, registers, memory)

        check:
            registers[R1] == 0xABCD
            registers[COND] == FL_NEG

    test "LDR (negative Base+Offset)":
        registers[R2] = 0x4005
        memory[0x4000] = 0x1234  # 0x4005 - 5

        let instr = uint16(0b0110001010111011) # LDR R1, R2, #-5

        ldr(instr, registers, memory)

        check:
            registers[R1] == 0x1234
            registers[COND] == FL_POS


suite "STORES - Condition Codes":

    setup:
        var registers: Registers
        var memory: Memory

    test "ST does not modify condition codes":
        registers[PC] = 0x3001
        registers[R1] = 0x1111
        registers[COND] = FL_NEG

        let instr = uint16(0b0011001000000101) # ST R1, #5

        st(instr, registers, memory)

        check:
            memory[0x3006] == 0x1111
            registers[COND] == FL_NEG

    test "STR does not modify condition codes":
        registers[R2] = 0x4000
        registers[R1] = 0x2222
        registers[COND] = FL_ZRO

        let instr = uint16(0b0111001010000101) # STR R1, R2, #5

        str(instr, registers, memory)

        check:
            memory[0x4005] == 0x2222
            registers[COND] == FL_ZRO

    test "STI does not modify condition codes":
        registers[PC] = 0x3001
        registers[R1] = 0x3333
        registers[COND] = FL_POS

        memory[0x3006] = 0x4500

        let instr = uint16(0b1011001000000101) # STI R1, #5

        sti(instr, registers, memory)

        check:
            memory[0x4500] == 0x3333
            registers[COND] == FL_POS