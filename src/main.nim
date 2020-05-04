import token, lexer, error

const Source = """
p = (1, 2)
b = block at (1, 2) "a^2+b^2 = c^2"

$pen = [red, thick] # Test comment
$filler = [blue]
draw ~ (0, 0) rectangle (2, 2)
filldraw path1

$*pen = [red, thick]
draw ~ circle p : 10

draw rectangle around b

for p in [p, b.center, b.top, (10, 20)]:
    draw ~ (-1, -1) -- p
"""

when isMainModule:
  try:
    let tokens = Source.lex()
    for t in tokens:
      echo t
  except AnalysisError:
    let e = (ref AnalysisError)(getCurrentException())
    e.handleAnalysisError(Source)
