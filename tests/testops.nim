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
