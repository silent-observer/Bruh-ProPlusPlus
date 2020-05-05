import token, ast, error

type Parser = object
  index: int
  input: seq[Token]

proc initParser(input: seq[Token]): Parser = 
  Parser(index: 0, input: input)
proc newParserError(t: Token, msg: string): ref AnalysisError =
  newAnalysisError(t.line, t.pos, t.index, msg)

proc current(p: Parser): Token = p.input[p.index]
proc lookahead(p: Parser, i: int = 1): Token = 
  if p.index + i < p.input.len:
    p.input[p.index + i]
  else: p.input[^1]
proc next(p: var Parser) = p.index.inc
proc checkSymbol(t: Token, s: string): bool = t.kind == Symbol and t.symbol == s
proc checkKeyword(t: Token, kw: KeywordKind): bool = t.kind == Keyword and t.keyword == kw
proc checkSymbolAndSkip(p: var Parser, s: string): bool =
  result = checkSymbol(p.current, s)
  if result: p.next()
proc checkKeywordAndSkip(p: var Parser, kw: KeywordKind): bool =
  result = checkKeyword(p.current, kw)
  if result: p.next()

proc accept(p: var Parser, k: TokenKind, msg: string) =
  if p.current.kind != k:
    raise p.current.newParserError(msg)
  p.next()
proc acceptSymbol(p: var Parser, s: string) =
  if p.current.kind != Symbol:
    raise p.current.newParserError("Expected \"" & s & "\" but got " & $p.current.kind)
  if p.current.symbol != s:
    raise p.current.newParserError("Expected \"" & s & "\" but got \"" & p.current.symbol & "\"")
  p.next()
proc acceptKeyword(p: var Parser, kw: KeywordKind) =
  if p.current.kind != Keyword:
    raise p.current.newParserError("Expected \"" & $kw & "\" but got " & $p.current.kind)
  if p.current.keyword != kw:
    raise p.current.newParserError("Expected \"" & $kw & "\" but got \"" &
                                   $p.current.keyword & "\"")
  p.next()

proc addInfo[T: AstNode](n: T, t: Token): T =
  n.line = t.line
  n.pos = t.pos
  n.index = t.index
  result = n

proc parseExpression(p: var Parser): ExpressionNode
proc parseParenExpr(p: var Parser): ExpressionNode
proc parseVectorExpr(p: var Parser): VectorExprNode =
  let t = p.current
  p.acceptSymbol("$")
  p.acceptSymbol("(")
  result = VectorExprNode().addInfo(t)
  result.coord.add p.parseExpression()
  while p.checkSymbolAndSkip(","):
    result.coord.add p.parseExpression()
  p.acceptSymbol(")")
proc parseListExpr(p: var Parser): ListExprNode =
  let t = p.current
  p.acceptSymbol("[")
  result = ListExprNode().addInfo(t)
  result.list.add p.parseExpression()
  while p.checkSymbolAndSkip(","):
    result.list.add p.parseExpression()
  p.acceptSymbol("]")

proc isExpressionStart(t: Token): bool =
  case t.kind:
    of Number, Id: true
    of Symbol: t.symbol in ["$", "(", "[", "~"]
    of Keyword: t.keyword == Block
    of String, Newline, Indent, Dedent, End: false
proc isPathComponentStart(t: Token): bool =
  case t.kind:
    of Number, Id: true
    of Symbol: t.symbol in ["$", "(", "[", "--", "..", "-|", "|-", "->", "<-", "<->"]
    of Keyword: t.keyword in {
      KeywordKind.Rectangle, KeywordKind.Circle, 
      KeywordKind.Arc, KeywordKind.Ellipse, Block
      }
    else: false

proc parsePathComponent(p: var Parser): PathComponent =
  if p.current.isExpressionStart:
    result = PathComponent(kind: Move, mainExpr: p.parseParenExpr())
  elif p.current.kind == Symbol:
    template simpleComponent(pcKind: untyped): untyped =
      p.next()
      result = PathComponent(kind: pcKind, mainExpr: p.parseParenExpr())
    case p.current.symbol:
      of "--": 
        p.next()
        if p.checkKeywordAndSkip(KeywordKind.Cycle):
          result = PathComponent(kind: Cycle)
        else:
          result = PathComponent(kind: Line, mainExpr: p.parseParenExpr())
      of "..": simpleComponent(Smooth)
      of "-|": simpleComponent(HorVert)
      of "|-": simpleComponent(VertHor)
      of "->": simpleComponent(ArrowForward)
      of "<-": simpleComponent(ArrowBackward)
      of "<->": simpleComponent(ArrowBoth)
      else: raise p.current.newParserError("Expected path component!")
  elif p.current.kind == Keyword:
    case p.current.keyword:
      of KeywordKind.Rectangle:
        p.next()
        if p.checkKeywordAndSkip(Around):
          result = PathComponent(kind: RectangleBlock)
        else:
          result = PathComponent(kind: Rectangle)
        result.mainExpr = p.parseParenExpr()
      of KeywordKind.Circle:
        p.next()
        if p.checkKeywordAndSkip(Around):
          result = PathComponent(kind: CircleBlock)
        else:
          result = PathComponent(kind: Circle)
        result.mainExpr = p.parseParenExpr()
      of KeywordKind.Arc:
        p.next()
        result.mainExpr = p.parseParenExpr()
        if p.checkKeywordAndSkip(Around):
          result = PathComponent(kind: ArcAround, arcCenter: p.parseParenExpr())
        elif p.checkSymbolAndSkip(":"):
          let e = p.parseParenExpr()
          if p.current.checkSymbol(":"):
            result = PathComponent(kind: Arc, fromAngle: e, toAngle: p.parseParenExpr())
          else:
            result = PathComponent(kind: ArcThrough, arcTo: e)
        else: raise p.current.newParserError("Expected \"around\" or \":\"!")
      of KeywordKind.Ellipse:
        p.next()
        result.mainExpr = p.parseParenExpr()
        if p.checkKeywordAndSkip(Around):
          result = PathComponent(kind: EllipseBlock, mainExpr: p.parseParenExpr())
        else:
          let e1 = p.parseParenExpr()
          p.acceptSymbol(":")
          let e2 = p.parseParenExpr()
          result = PathComponent(kind: Ellipse, mainExpr: e1, yAxis: e2)
      else: raise p.current.newParserError("Expected path component!")
proc parsePathExpr(p: var Parser): PathExprNode =
  let t = p.current
  p.acceptSymbol("~")
  result = PathExprNode().addInfo(t)
  while p.current.isPathComponentStart:
    result.path.add p.parsePathComponent()
    echo p.current
  echo p.current
  p.acceptSymbol("~")
  echo p.current

proc parseBlockExpr(p: var Parser): BlockExprNode =
  let t = p.current
  p.acceptKeyword(Block)
  p.acceptKeyword(At)
  let pos = p.parseParenExpr()
  if p.checkKeywordAndSkip(With):
    if p.checkKeywordAndSkip(Size):
      result = BlockExprNode(kind: BlockWithSize, at: pos, vector: p.parseParenExpr()).addInfo(t)
    elif p.checkKeywordAndSkip(Padding):
      result = BlockExprNode(kind: BlockWithPadding, at: pos, vector: p.parseParenExpr()).addInfo(t)
    else:
      raise p.current.newParserError("Expected \"size\" or \"padding\"!")
  else:
    result = BlockExprNode(kind: NormalBlock, at: pos).addInfo(t)
  if p.checkSymbolAndSkip(":"):
    if p.current.kind != String:
      raise p.current.newParserError("Expected text constant")
    result.text = p.current.str
    p.next()
  else:
    result.text = ""

proc parseAtomExpr(p: var Parser): ExpressionNode =
  let t = p.current
  if p.current.kind == Number:
    result = NumExprNode(number: p.current.number).addInfo(t)
    p.next()
  elif p.current.kind == Id:
    result = VarExprNode(name: p.current.id).addInfo(t)
    p.next()
  elif p.current.checkSymbol("$"):
    result = p.parseVectorExpr()
  elif p.current.checkSymbol("~"):
    result = p.parsePathExpr()
  elif p.current.checkSymbol("["):
    result = p.parseListExpr()
  elif p.current.checkKeyword(Block):
    result = p.parseBlockExpr()
  else:
    raise p.current.newParserError("Expected expression!")
proc parseParenExpr(p: var Parser): ExpressionNode =
  if p.checkSymbolAndSkip("("):
    result = p.parseExpression()
    p.acceptSymbol(")")
  else:
    result = p.parseAtomExpr()
proc parseMultExpr(p: var Parser): ExpressionNode =
  let t = p.current
  result = p.parseParenExpr()
  while p.current.checkSymbol("*") or p.current.checkSymbol("/"):
    let op = if p.current.symbol == "*": Mult else: Div
    p.next()
    let rightExpr = p.parseParenExpr()
    result = BinaryExprNode(kind: op, left: result, right: rightExpr).addInfo(t)
proc parseExpression(p: var Parser): ExpressionNode =
  let t = p.current
  result = p.parseMultExpr()
  while p.current.checkSymbol("+") or p.current.checkSymbol("-"):
    let op = if p.current.symbol == "+": Add else: Sub
    let rightExpr = p.parseMultExpr()
    result = BinaryExprNode(kind: op, left: result, right: rightExpr).addInfo(t)

proc isStatementStart(t: Token): bool =
  case t.kind:
    of Symbol: t.symbol == "$"
    of Keyword: t.keyword in {
      KeywordKind.Draw, KeywordKind.Fill, KeywordKind.FillDraw
      }
    of Id: true
    else: false

proc parseStatement(p: var Parser): StatementNode
proc parseAssignStat(p: var Parser): AssignNode =
  result = AssignNode().addInfo(p.current)
  if p.checkSymbolAndSkip("$"):
    result.isSpecial = true
    if p.checkSymbolAndSkip("*"):
      result.isOneTime = true
  if p.current.kind != Id:
    raise p.current.newParserError("Expected variable name!")
  result.varName = p.current.id
  p.next()
  p.acceptSymbol("=")
  result.val = p.parseExpression()
  p.accept(Newline, "Expected newline!")
proc parseCommandStat(p: var Parser): CommandNode =
  result = CommandNode().addInfo(p.current)
  if p.current.kind != Keyword or 
      (p.current.keyword notin {KeywordKind.Draw, KeywordKind.Fill, KeywordKind.FillDraw}):
    raise p.current.newParserError("Expected \"draw\", \"fill\" or \"filldraw\"!")
  case p.current.keyword:
    of KeywordKind.Draw: result.kind = Draw
    of KeywordKind.Fill: result.kind = Fill
    of KeywordKind.FillDraw: result.kind = FillDraw
    else: discard
  p.next()
  result.val = p.parseExpression()
  p.accept(Newline, "Expected newline!")
proc parseStatBlock(p: var Parser): seq[StatementNode] =
  p.accept(Indent, "Expected more indentation!")
  while p.current.isStatementStart:
    result.add p.parseStatement()
  p.accept(Dedent, "Expected less indentation!")
proc parseForStat(p: var Parser): ForNode =
  result = ForNode().addInfo(p.current)
  p.acceptKeyword(For)
  if p.current.kind != Id:
    raise p.current.newParserError("Expected variable name!")
  result.varName = p.current.id
  p.next()
  p.acceptKeyword(In)
  result.list = p.parseExpression()
  p.acceptSymbol(":")
  p.accept(Newline, "Expected newline!")
  result.body = p.parseStatBlock()

proc parseStatement(p: var Parser): StatementNode =
  if p.current.kind == Id or p.current.checkSymbol("$"):
    p.parseAssignStat()
  elif p.current.kind == Keyword and 
      (p.current.keyword in {KeywordKind.Draw, KeywordKind.Fill, KeywordKind.FillDraw}):
    p.parseCommandStat()
  elif p.current.checkKeyword(For):
    p.parseForStat()
  else:
    raise p.current.newParserError("Expected statement!")

proc parse*(input: seq[Token]): seq[StatementNode] =
  var p = initParser(input)
  while p.current.kind != End:
    while p.current.kind == Newline: p.next()
    result.add p.parseStatement()
    while p.current.kind == Newline: p.next()