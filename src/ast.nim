from strutils import spaces

type
  AstNode* = ref object of RootObj
    line*, pos*, index*: int
  StatementNode* = ref object of AstNode
  ExpressionNode* = ref object of AstNode

  AssignNode* = ref object of StatementNode
    isSpecial*: bool
    isOneTime*: bool
    varName*: string
    val*: ExpressionNode
  CommandNodeKind* = enum
    Draw = "draw", Fill = "fill", FillDraw = "filldraw"
  CommandNode* = ref object of StatementNode
    kind* : CommandNodeKind
    val*: ExpressionNode
  ForNode* = ref object of StatementNode
    varName*: string
    list*: ExpressionNode
    body*: seq[StatementNode]
  
  BinaryExprKind* = enum
    Add = "+", Sub = "-", Mult = "*", Div = "/"
  BinaryExprNode* = ref object of ExpressionNode
    kind*: BinaryExprKind
    left*: ExpressionNode
    right*: ExpressionNode
  UnaryExprKind* = enum
    Negate
  UnaryExprNode* = ref object of ExpressionNode
    kind*: UnaryExprKind
    val*: ExpressionNode
  NumExprNode* = ref object of ExpressionNode
    number*: float
  VarExprNode* = ref object of ExpressionNode
    name*: string
  VectorExprNode* = ref object of ExpressionNode
    coord*: seq[ExpressionNode]

  PathComponentKind* = enum
    Move, Line = "--", Smooth = "..", HorVert = "-|", VertHor = "|-",
    ArrowForward = "->", ArrowBackward = "<-", ArrowBoth = "<->",
    Cycle, Rectangle, RectangleBlock, Circle, CircleAround,
    CircleBlock, Arc, ArcAround, ArcThrough, Ellipse, EllipseBlock
  PathComponent* = object
    mainExpr*: ExpressionNode
    case kind*: PathComponentKind:
      of Move: nil
      of Line, Smooth, HorVert, VertHor,
         ArrowForward, ArrowBackward, ArrowBoth: nil
      of Cycle: nil
      of RectangleBlock, CircleBlock, EllipseBlock: nil
      of Rectangle, Circle, CircleAround: nil
      of Arc: fromAngle*, toAngle*: ExpressionNode
      of ArcAround: arcCenter*: ExpressionNode
      of ArcThrough: arcTo*: ExpressionNode
      of Ellipse: yAxis*: ExpressionNode
  PathExprNode* = ref object of ExpressionNode
    path*: seq[PathComponent]
  ListExprNode* = ref object of ExpressionNode
    list*: seq[ExpressionNode]
  BlockExprKind* = enum
    NormalBlock, BlockWithSize, BlockWithPadding
  BlockExprNode* = ref object of ExpressionNode
    at*: ExpressionNode
    case kind*: BlockExprKind:
      of NormalBlock: nil
      of BlockWithSize, BlockWithPadding: vector*: ExpressionNode
    text*: string
  
method toString(n: AstNode, indent: int = 0): string {.base.} = "NOT IMPLEMENTED"

method toString(n: AssignNode, indent: int): string =
  result = spaces(indent * 4)
  if n.isSpecial: result &= "$"
  if n.isOneTime: result &= "*"
  result &= n.varName & " = " & n.val.toString(indent) & "\n"
method toString(n: CommandNode, indent: int): string =
  spaces(indent * 4) & $n.kind & " " & n.val.toString(indent) & "\n"
method toString(n: ForNode, indent: int): string =
  result = spaces(indent * 4) & "for " & n.varName & " in " & n.list.toString(indent) & ":\n"
  for s in n.body:
    result &= s.toString(indent + 1)

method toString(n: BinaryExprNode, indent: int): string =
  "(" & n.left.toString() & ")" & $n.kind & "(" & n.right.toString() & ")"
method toString(n: UnaryExprNode, indent: int): string =
  "-(" & n.val.toString() & ")"
method toString(n: NumExprNode, indent: int): string = $n.number
method toString(n: VarExprNode, indent: int): string = n.name
method toString(n: VectorExprNode, indent: int): string =
  result = "$("
  for e in n.coord[0 ..< ^1]: result &= e.toString() & ", "
  result &= n.coord[^1].toString() & ")"
proc `$`*(p: PathComponent): string =
  case p.kind:
    of Move: p.mainExpr.toString()
    of Line, Smooth, HorVert, VertHor,
       ArrowForward, ArrowBackward, ArrowBoth: $p.kind & " " & p.mainExpr.toString()
    of Cycle: "-- cycle"
    of Rectangle: "rectangle " & p.mainExpr.toString()
    of RectangleBlock: "rectangle around " & p.mainExpr.toString()
    of Circle: "circle " & p.mainExpr.toString()
    of CircleAround, CircleBlock: "circle around " & p.mainExpr.toString()
    of Arc: "arc " & p.mainExpr.toString() & " : " & 
            p.fromAngle.toString() & " : " & p.toAngle.toString()
    of ArcAround: "arc " & p.mainExpr.toString() & " around " & p.arcCenter.toString()
    of ArcThrough: "arc " & p.mainExpr.toString() & " : " & p.arcTo.toString()
    of Ellipse: "ellipse " & p.mainExpr.toString() & " : " & p.yAxis.toString()
    of EllipseBlock: "ellipse around " & p.mainExpr.toString()
method toString(n: PathExprNode, indent: int): string =
  result = "~ "
  for c in n.path: result &= $c & " "
  result &= "~"
method toString(n: ListExprNode, indent: int): string =
  result = "["
  for e in n.list[0 ..< ^1]: result &= e.toString() & ", "
  result &= n.list[^1].toString() & "]"
method toString(n: BlockExprNode, indent: int): string =
  result = "block at " & n.at.toString()
  case n.kind:
    of NormalBlock: discard
    of BlockWithSize: result &= " with size " & n.vector.toString()
    of BlockWithPadding: result &= " with padding " & n.vector.toString()
  if n.text != "": result &= ": \"" & n.text & "\""
proc `$`*(n: AstNode): string {.inline.} = n.toString(0)