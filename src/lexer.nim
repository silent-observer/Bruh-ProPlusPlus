import error
import token
import strutils, parseutils

type Lexer = object
  line, pos, index: int
  indents: seq[int]
  dedentsLeft: int
  input: string

const SymbolStart = 
  {'+', '-', '*', '/', '$', '<', '>', '=', '.', ':', '|', '(', ')', '[', ']', ',', '~'}

proc initLexer(input: string): Lexer = 
  Lexer(line: 1, pos: 1, index: 0, indents: @[0], dedentsLeft: 0, input: input)
proc newLexerError(l: Lexer, msg: string): ref AnalysisError =
  newAnalysisError(l.line, l.pos, l.index, msg)

proc addInfo(t: Token, l: Lexer): Token =
  result = t
  result.line = l.line
  result.pos = l.pos
  result.index = l.index

proc lexWord(l: var Lexer): Token =
  let s = l.input.parseIdent(l.index)
  l.pos += s.len
  l.index += s.len
  
  for keyword in KeywordKind.low .. KeywordKind.high:
    if $keyword == s:
      return Token(kind: Keyword, keyword: keyword).addInfo(l)
  Token(kind: Id, id: s).addInfo(l)

proc lexSymbol(l: var Lexer): Token =
  template c: char = l.input[l.index]
  let startIndex = l.index
  case c:
    of '+', '*', '/', '$', ':', '=', '(', ')', '[', ']', ',', '~': l.index.inc
    of '-':
      l.index.inc
      if c in {'-', '>', '|'}: l.index.inc
    of '<': 
      l.index.inc
      if c == '-':
        l.index.inc
        if c == '>':
          l.index.inc
      elif c == '=': l.index.inc
    of '>':
      l.index.inc
      if c == '=': l.index.inc
    of '.':
      l.index.inc
      if c == '.': l.index.inc
    of '|':
      l.index.inc
      if c != '-': raise l.newLexerError("\"|\" is invalid!")
      l.index.inc
    else: discard
  l.pos += l.index - startIndex
  Token(kind: Symbol, symbol: l.input[startIndex ..< l.index]).addInfo(l)

proc lexNumber(l: var Lexer): Token =
  template c: char = l.input[l.index]
  let sign = 
    if c == '-':
      l.index.inc
      l.pos.inc
      -1
    else: 1
  var f: float
  let count = l.input.parseFloat(f, l.index)
  if count == 0 and sign == -1:
    l.index.dec
    l.pos.dec
    return l.lexSymbol()
  if count == 0: raise l.newLexerError("Invalid number!")
  l.pos += count
  l.index += count
  Token(kind: Number, number: f).addInfo(l)

proc lexString(l: var Lexer): Token =
  l.index.inc
  l.pos.inc
  var i = l.index
  while true:
    i += l.input.skipUntil({'\\', '\"', '\n'}, i)
    if i == l.input.len: raise l.newLexerError("String is not closed!")
    if l.input[i] == '\n': raise l.newLexerError("Newline in string!")
    if l.input[i] == '\"': break
    i.inc
  let s = l.input[l.index ..< i]
  l.pos += i - l.index + 1
  l.index = i + 1
  Token(kind: String, str: s).addInfo(l)

proc lexToken(l: var Lexer): Token
proc lexWhitespace(l: var Lexer): Token =
  template c: char = l.input[l.index]
  while c in {' ', '\n', '\r', '\t'}:
    if l.pos == 1:
      while c == ' ' or c == '\r':
        l.pos.inc
        l.index.inc
      if c == '\t': raise l.newLexerError("Tabs are prohibited!")
      if c == '\n':
        l.pos = 1
        l.line.inc
        l.index.inc
        continue
      if l.pos - 1 == l.indents[^1]: continue
      elif l.pos - 1 > l.indents[^1]:
        l.indents.add(l.pos - 1)
        return Token(kind: Indent).addInfo(l)
      else:
        while l.indents[^1] > l.pos - 1:
          l.dedentsLeft.inc
          discard l.indents.pop()
        if l.indents[^1] != l.pos - 1:
          raise l.newLexerError("Weird indentation, use normal indentation levels!")
        l.dedentsLeft.dec
        return Token(kind: Dedent).addInfo(l)
    else:
      while c == ' ' or c == '\r':
        l.pos.inc
        l.index.inc
      if c == '\t': raise l.newLexerError("Tabs are prohibited!")
      if c == '\n':
        l.pos = 1
        l.line.inc
        l.index.inc
        return Token(kind: Newline).addInfo(l)
  return l.lexToken()

proc lexToken(l: var Lexer): Token =
  if l.dedentsLeft > 0:
    l.dedentsLeft.dec
    return Token(kind: Dedent).addInfo(l)

  template c: char = l.input[l.index]
  if l.index == l.input.len: 
    return Token(kind: End).addInfo(l)
  if c == '#':
    let count = l.input.skipUntil('\n', l.index)
    l.index += count
    l.pos += count
  
  if l.index == l.input.len: 
    return Token(kind: End).addInfo(l)
  if c.isAlphaAscii:
    return l.lexWord()
  if c == '-' or c.isDigit:
    return l.lexNumber()
  if c in SymbolStart:
    return l.lexSymbol()
  if c == '"':
    return l.lexString()
  if c in {' ', '\n', '\r', '\t'}:
    return l.lexWhitespace()
  raise l.newLexerError("Unknown symbol!")

proc lex*(input: string): seq[Token] =
  var lexer = initLexer(input)
  while true:
    let t = lexer.lexToken()
    if t.kind == End: break
    result.add t
  for i in 1 ..< lexer.indents.len:
    result.add Token(kind: Dedent).addInfo(lexer)
  result.add Token(kind: End).addInfo(lexer)