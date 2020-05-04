from parseutils import parseUntil
from strutils import spaces

type AnalysisError* = object of ValueError
  line, pos, index: int

proc newAnalysisError*(line, pos, index: int, msg: string): ref AnalysisError =
  new(result)
  result.line = line
  result.pos = pos
  result.index = index
  result.msg = msg

proc handleAnalysisError*(e: ref AnalysisError, src: string) =
  echo "\x1b[31mError occured!\x1b[0m\n", e.msg, "\nLine ", e.line, ":"
  let lineStart = e.index - (e.pos - 1)
  var lineString: string
  discard src.parseUntil(lineString, {'\n', '\r'}, lineStart)
  echo lineString
  if e.pos - 1 >= 0:
    echo spaces(e.pos - 1) & "\x1b[31m^\x1b[0m"