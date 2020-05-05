type 
  TokenKind* {.pure.} = enum
    Id, Symbol, Number, String, Keyword, NewLine, Indent, Dedent, End
  KeywordKind* {.pure.} = enum
    Block = "block", At = "at", With = "with", Size = "size", Padding = "padding",
    Cycle = "cycle", Around = "around", Rectangle = "rectangle", Circle = "circle",
    Arc = "arc", Ellipse = "ellipse", For = "for", In = "in",
    Draw = "draw", Fill = "fill", FillDraw = "filldraw"
  Token* = object
    line*, pos*, index*: int
    case kind*: TokenKind:
      of Id: 
        id*: string
      of Symbol:
        symbol*: string
      of String:
        str*: string
      of Number:
        number*: float
      of Keyword: keyword*: KeywordKind
      of NewLine, Indent, Dedent, End: nil