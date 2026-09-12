import std/cmdline
import std/enumerate
import std/strformat
import std/sequtils
import std/strutils
import std/sets
import std/re
import alltypes

const instructions = toHashSet(["BR", "ADD", "LD", "ST", "JSR", "AND", "LDR", "STR", "RTI", "NOT", "LDI", "STI", "JMP", "RES", "LEA", "TRAP"])
const pseudoInstructions = toHashSet([".ORIG", ".END", ".BLKW", ".FILL", ".STRINGZ"])

const
  whitespace = re"\s+"
  commaWhitespace = re",\s+"

proc tokenizeComments(words: seq[string]): seq[Token] =
  var comment = false
  for word in words:
    if word == ";":
      comment = true
    elif word.startsWith(";"):
      comment = true
      result.add(Token(tokenType: COMMENT, value: word[1..^1]))
    else:
      if comment:
        result.add(Token(tokenType: COMMENT, value: word))

proc tokenizeInstruction(words: seq[string]): seq[Token] =
  result = @[Token(tokenType: OPCODE, value: words[0])]

  let operands = words[1].split(",")
  var curr = 0
  while curr < operands.len():
    let operand = operands[curr].strip()
    curr += 1
    if operand.startsWith("#"):
      result.add(Token(tokenType: IMMOPERAND, value: operand))
    elif operand.startsWith("R"):
      result.add(Token(tokenType: REGOPERAND, value: operand))
    else:
      result.add(Token(tokenType: LABELOPERAND, value: operand))

  # if words.len() > 2:
  #   result = result & tokenizeComments(words[2..^1])

proc tokenizePseudoInstruction(words: seq[string]): seq[Token] =
  result = @[Token(tokenType: PSEUDOOPCODE, value: words[0])]
  if words.len() > 1:
    result.add(Token(tokenType: PSEUDOOPERAND, value: words[1]))

  # if words.len() > 2:
  #   result = result & tokenizeComments(words[2..^1])

proc tokenize(words: seq[string], index: int = 0): seq[Token] =
  if words.len() == 0:
    return
  if words[0] == ";":
    for word in words[1..^1]:
      result.add(Token(tokenType: COMMENT, value: word))
    return
  if words[0] in instructions:
    result = tokenizeInstruction(words)
  # elif words[0].startsWith("."):
  elif words[0] in pseudoInstructions:
    result = tokenizePseudoInstruction(words)
  else:
    if index == 1:
      raise newException(TokenError, "Only 1 label per line is allowed.")
    let label = Token(tokenType: LABEL, value: words[0])
    result.add(label)
    result = result & tokenize(words[1..^1], index + 1)


proc classifyLine(line: var Line): LineNode =
  # standalone comment
  # if line.text[0] == ';':
  #   result = LineNode(lineType: COMMENT, TEXT: line.text)
  #   return
  let cleanLine = line.text.replace(whitespace, " ").replace(commaWhitespace, ",")
  let words = cleanLine.split(" ") # Add a, b, c => Add, 'a,', 'b,', 'c,'
  let tokens = tokenize(words)

  case tokens[0].tokenType:
  of OPCODE:
    # if we tokenized comments, we need to get the index from where comments start, from the prev procs
    result = LineNode(lineType: INSTRUCTION, OPCODE: tokens[0].value, OPERANDS: tokens[1..^1])
  of PSEUDOOPCODE:
    # if we tokenized comments, we need to get the index from where comments start, from the prev procs
    result = LineNode(lineType: PSEUDOINSTRUCTION, PSEUDOPCODE: tokens[0].value, PSEUDOOPERANDS: tokens[1..^1])
  of LABEL:
    result = LineNode(lineType: LABEL, NAME: tokens[0].value, OFFSET: line.number)
  of COMMENT:
    result = LineNode(lineType: COMMENT, TEXT: tokens[0].value)
  else:
    result = LineNode(lineType: UNKNOWN, DATA: tokens)


proc readAsmFile(name: string): seq[LineNode] =
  for (i, line) in enumerate(lines(name)):
    let val = line.strip()
    if val.isEmptyOrWhitespace():
      continue
    var currLine = Line(number: i, text: val)
    let node = classifyLine(currLine)
    result.add(node)

proc assemble(name: string): bool =
  let data = name.readAsmFile()
  if data.len() == 0:
    result = false
  else:
    echo(data)
    result = true

proc main() =
  let args = commandLineParams()
  if args.len() == 0:
    echo("./lc3as [assembly-file1] [assembly-file2] ...")
    quit(1)

  for arg in args:
    try:
      let success = assemble(arg)
      if success == false:
        echo(&"failed to assemble file: {arg}")
        quit(1)
    except TokenError as e:
      echo(&"assembly error: {e.msg}")
      quit(1)

when isMainModule:
  main()
