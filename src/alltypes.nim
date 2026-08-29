const MEMORYMAX = 65535

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

