import unittest

import std/strutils
import ../src/alltypes
import ../src/lc3as


type
    LineRef = ref Line

suite "Tokenization":

    test "instruction register operands":

        var line = LineRef(
            number: 0,
            text: "ADD R1, R2, R3"
        )

        let node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "ADD"
        check node.OPERANDS.len == 3

        check node.OPERANDS[0].tokenType == REGOPERAND
        check node.OPERANDS[0].value == "R1"

        check node.OPERANDS[1].tokenType == REGOPERAND
        check node.OPERANDS[1].value == "R2"

        check node.OPERANDS[2].tokenType == REGOPERAND
        check node.OPERANDS[2].value == "R3"


    test "instruction immediate operand":

        var line = LineRef(
            number: 0,
            text: "ADD R1, R2, #5"
        )

        let node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "ADD"

        check node.OPERANDS[0].tokenType == REGOPERAND
        check node.OPERANDS[1].tokenType == REGOPERAND
        check node.OPERANDS[2].tokenType == IMMOPERAND

        check node.OPERANDS[2].value == "#5"


    test "instruction negative immediate":

        var line = LineRef(
            number: 0,
            text: "ADD R1, R2, #-5"
        )

        let node = classifyLine(line)

        check node.OPERANDS[2].tokenType == IMMOPERAND
        check node.OPERANDS[2].value == "#-5"


    test "instruction label operand":

        var line = LineRef(
            number: 0,
            text: "BR LOOP"
        )

        let node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "BR"

        check node.OPERANDS.len == 1
        check node.OPERANDS[0].tokenType == LABELOPERAND
        check node.OPERANDS[0].value == "LOOP"


    test "label followed by instruction":

        var line = LineRef(
            number: 4,
            text: "LOOP ADD R1, R2, R3"
        )

        let node = classifyLine(line)

        check node.lineType == LABEL
        check node.NAME.value == "LOOP"


    test "label only":

        var line = LineRef(
            number: 4,
            text: "LOOP"
        )

        let node = classifyLine(line)

        check node.lineType == LABEL
        check node.NAME.value == "LOOP"


    test "pseudo instruction":

        var line = LineRef(
            number: 0,
            text: ".ORIG x3000"
        )

        let node = classifyLine(line)

        check node.lineType == PSEUDOINSTRUCTION
        check node.PSEUDOPCODE.value == ".ORIG"
        check node.PSEUDOOPERANDS.len == 1
        check node.PSEUDOOPERANDS[0].tokenType == PSEUDOOPERAND


    test "instruction with extra whitespace":

        var line = LineRef(
            number: 0,
            text: "ADD    R1,    R2,     #5"
        )

        let node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "ADD"
        check node.OPERANDS.len == 3


    test "standalone comment":

        var line = LineRef(
            number: 0,
            text: "; hello world"
        )

        let node = classifyLine(line)

        check node.lineType == COMMENT


    test "comment only":

        var line = LineRef(
            number: 0,
            text: ";"
        )

        let node = classifyLine(line)

        check node.lineType == UNKNOWN


    test "comment after instruction":

        var line = LineRef(
            number: 0,
            text: "ADD R1, R2, R3 ; increment"
        )

        let node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "ADD"


    test "comment without whitespace":

        var line = LineRef(
            number: 0,
            text: "ADD R1, R2, R3 ;increment"
        )

        let node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "ADD"


    test "tab separated instruction":

        var line = LineRef(
            number: 0,
            text: "ADD\tR1,\tR2,\t#5"
        )

        let node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "ADD"
        check node.OPERANDS.len == 3


    test "leading and trailing whitespace":
        let val = "   ADD R1, R2, R3   "
        var line = LineRef(
            number: 0,
            text: val.strip() # simulates readAsmFile
        )

        let node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "ADD"


    test "different instruction forms":

        var line = LineRef(
            number: 0,
            text: "BR LOOP"
        )

        var node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "BR"
        check node.OPERANDS[0].tokenType == LABELOPERAND


        line.text = "ADD R0, R1, #5"

        node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "ADD"
        check node.OPERANDS[2].tokenType == IMMOPERAND


        line.text = "LDR R0, R1, #-5"

        node = classifyLine(line)

        check node.lineType == INSTRUCTION
        check node.OPCODE.value == "LDR"
        check node.OPERANDS[2].tokenType == IMMOPERAND


    test "all pseudo instruction opcodes":

        for opcode in [".ORIG", ".END", ".BLKW", ".FILL", ".STRINGZ"]:

            var line = LineRef(
                number: 0,
                text: opcode
            )

            let node = classifyLine(line)

            check node.lineType == PSEUDOINSTRUCTION
            check node.PSEUDOPCODE.value == opcode


    test "register-like operand":

        var line = LineRef(
            number: 0,
            text: "ADD R1, R2, R10"
        )

        let node = classifyLine(line)

        check node.OPERANDS[0].tokenType == REGOPERAND
        check node.OPERANDS[1].tokenType == REGOPERAND
        check node.OPERANDS[2].tokenType == REGOPERAND

        check node.OPERANDS[2].value == "R10"


    test "two labels":

        var line = LineRef(
            number: 0,
            text: "FOO BAR ADD R1, R2, R3"
        )

        expect TokenError:
            discard classifyLine(line)


    test "multiple unknown tokens":

        var line = LineRef(
            number: 0,
            text: "FOO BAR BAZ"
        )

        expect TokenError:
            discard classifyLine(line)