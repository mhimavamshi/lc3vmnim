# VM Types

const
  MEMORYMAX* = 0x10000
  START* = 0x3000

type
  Register* = enum
    R0,
    R1,
    R2,
    R3,
    R4,
    R5,
    R6,
    R7,
    PC,
    COND

  Opcodes* = enum
    BR,
    ADD,
    LD,
    ST,
    JSR,
    AND,
    LDR,
    STR,
    RTI,
    NOT,
    LDI,
    STI,
    JMP,
    RES,
    LEA,
    TRAP

  Flags* = uint16

  TrapCode* = enum 
    GETC = 0x20, 
    OUT = 0x21,
    PUTS = 0x22,
    IN = 0x23, 
    PUTSP = 0x24,
    HALT = 0x25   
  
  Memory* = array[MEMORYMAX, uint16]
  Registers* = array[Register, uint16]

  Running* = distinct bool 


const   
  FL_POS* = Flags(1'u16)
  FL_ZRO* = Flags(2'u16)
  FL_NEG* = Flags(4'u16)

  MR_KBSR* = 0xFE00'u16
  MR_KBDR* = 0xFE02'u16

# Assembler Types
import std/options

type 
  LineType* = enum 
    INSTRUCTION,
    PSEUDOINSTRUCTION,
    COMMENT,
    LABEL,
    UNKNOWN

  TokenType* = enum 
    OPCODE,
    PSEUDOOPCODE,
    PSEUDOOPERAND,
    REGOPERAND,
    IMMOPERAND,
    LABELOPERAND,
    LABEL,
    COMMENT

  Token* = object 
    tokenType*: TokenType
    value*: string

  LineNode* = ref object
    case lineType*: LineType
      of INSTRUCTION:
        OPCODE*: Token 
        OPERANDS*: seq[Token]  
      of COMMENT:
        TEXT*: string 
      of LABEL:
        NAME*: Token
        OFFSET*: int
        BODY*: Option[LineNode]
      of PSEUDOINSTRUCTION:
        PSEUDOPCODE*: Token
        PSEUDOOPERANDS*: seq[Token]
      of UNKNOWN:
        DATA*: seq[Token] 
    line*: Option[ref Line]

  Line* = object 
    number*: int
    text*: string 

  TokenError* = object of ValueError
  FirstPassError* = object of ValueError
