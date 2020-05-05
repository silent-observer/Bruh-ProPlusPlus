# Bruh Pro++
Vector graphics description language (don't ask about the name)

## Description

The main object in the language is a point. It consists of 2 coordinates: x and y, and is defined as
```
p = $(1, 2)
```
Language is dynamic typed, so you don't have to declare all the types. There are also are blocks:
```
b = block at $(1, 2): "a^2+b^2 = c^2"
```
Yes, it supports LaTeX math. Block is the same as point except that it has dimensions too and 
can contain text. You can specify size exactly:
```
b = block at p with size $(10, 20)
```
Or add "padding" as you would with CSS:
```
b = block at p with padding $(2, 5): $a^2+b^2 = c^2$
```
You can also specify paths:
```
path1 = ~ p -- $(1, 3) -> $(2, 3) ~
```
To actually draw anything you can use commands. There are also special variables starting with `$` and `$*`:
```
$pen = [red, thick]
$filler = [blue]
draw ~ $(0, 0) rectangle $(2, 2) ~
filldraw path1
$*pen = [red, thick]
draw ~ circle p : 10 ~
draw ~ rectangle around b ~
```
`$*` means that the variable is set only for the next graphic command
For positioning you can use vector arithmetic:
```
a = $(1, 2)
b = $(3, 4)
c = (a + b) / 2
```
There are also foreach loops:
```
for p in [p, b.center, b.top, (10, 20)]:
    draw ~ $(-1, -1) -- p ~
```
Yes, indentation matters, this is Python like syntax

## Available commands
### Point/vector expressions
- [ ] Vector literal
- [ ] Vector arithmetic
### Block expressions
- [ ] `block at <point>`
- [ ] Block text
- [ ] `block with size <vector>`
- [ ] `block with padding <vector>`
### Path expressions
- [ ] `--`
- [ ] `|-` + `-|`
- [ ] `-- cycle`
- [ ] `->` + `<-` + `<->`
- [ ] `..`
- [ ] `rectangle`
    - [ ] `rectangle <point>`
    - [ ] `rectangle around <block>`
- [ ] `circle`
    - [ ] `circle <radius>`
    - [ ] `circle around <center>`
    - [ ] `circle around <block>`
- [ ] `arc`
    - [ ] `arc <radius> : <from angle> : <to angle>`
    - [ ] `arc <to point> around <point>`
    - [ ] `arc <mid point> : <to point>`
- [ ] `ellipse`
    - [ ] `ellipse <x axis> : <y axis>`
    - [ ] `ellipse around <block>`
### Misc
- [ ] Color expression
    - [ ] `hex`
### Special variables
- [ ] `pen`
    - [ ] `color`
    - [ ] `red`, `green`, `blue`, `black`, `yellow`
    - [ ] `thickness`
    - [ ] `thick`, `thin`
- [ ] `filler`
    - [ ] `color`
    - [ ] `opacity`
### Control instructions
- [ ] `for <var> in [...]`
### Drawing commands
- [ ] `draw <path>`
- [ ] `fill <path>`
- [ ] `filldraw <path>`

## Grammar
```ebnf
expression = mult expr, {("+" | "-"), mult expr};
mult expr = paren expr, {("*" | "/"), paren expr};
paren expr = atom expr | "(", expression, ")";
atom expr = number symbol | id symbol | vector expr
          | path expr | list expr | block expr;

vector expr = "$", "(", expression, {",", expression}, ")";
path expr = "~", {path component}, "~";
path component = paren expr | line op, paren expr | "--", "cycle"
               | "rectangle", ["around"], paren expr
               | "circle", ["around"], paren expr
               | "arc", paren expr,
                    ("around", paren expr | ":", paren expr, [":", paren expr])
               | "ellipse", (paren expr, ":", paren expr | "around", paren expr);
line op = "--" | ".." | "-|" | "|-" | "->" | "<-" | "<->";
list expr = "[" [expression, {",", expression}] "]";
block expr = "block", "at", paren expression,
             ["with", ("size" | "paddings"), paren expression],
             [":", string symbol];

statement = assign stat | command stat | for stat | newline symbol;
assign stat = ["$", ["*"]], id symbol, "=", expression, newline symbol;
command stat = ("draw" | "fill" | "filldraw"), expression, newline symbol;
for stat = "for", id symbol, "in", expression, ":", newline symbol, block;
block = indent symbol, {statement}, dedent symbol;
```