# Bruh Pro++
Vector graphics description language (don't ask about the name)

## Description

The main object in the language is a point. It consists of 2 coordinates: x and y, and is defined as
```
p = (1, 2)
```
Language is dynamic typed, so you don't have to declare all the types. There are also are blocks:
```
b = block at (1, 2) "$a^2+b^2 = c^2$"
```
Yes, it supports LaTeX math. Block is the same as point except that it has dimensions too and 
can contain text. You can specify size exactly:
```
b = block at p with size (10, 20)
```
Or add "paddings" as you would with CSS:
```
b = block at p with paddings (2, 5): $a^2+b^2 = c^2$
```
You can also specify paths:
```
path1 = ~ p -- (1, 3) -> (2, 3)
```
To actually draw anything you can use commands. There are also special variables starting with `$` and `$*`:
```
$pen = [red, thick]
$filler = [blue]
draw ~ (0, 0) rectangle (2, 2)
filldraw path1
$*pen = [red, thick]
draw ~ circle p : 10
draw rectangle around b
```
`$*` means that the variable is set only for the next graphic command
For positioning you can use vector arithmetic:
```
a = (1, 2)
b = (3, 4)
c = (a + b) / 2
```
There are also foreach loops:
```
for p in [p, b.center, b.top, (10, 20)]:
    draw ~ (-1, -1) -- p
```
Yes, indentation matters, this is Python-like syntax

## Available commands
### Point/vector expressions
- [ ] Vector literal
- [ ] Vector arithmetic
### Block expressions
- [ ] `block at <point>`
- [ ] Block text
- [ ] `block with size <vector>`
- [ ] `block with paddings <vector>`
### Path expressions
- [ ] `--`
- [ ] `|-` + `-|`
- [ ] `--cycle`
- [ ] `->` + `<-` + `<->`
- [ ] `..`
- [ ] `rectangle`
    - [ ] `rectangle <point>`
    - [ ] `rectangle around <block>`
- [ ] `circle`
    - [ ] `circle <center> : <radius>`
    - [ ] `circle from <point> around <center>`
    - [ ] `circle around <block>`
- [ ] `arc`
    - [ ] `arc <center> : <radius> : <from angle> : <to angle>`
    - [ ] `arc <from point> : <to point> around <point>`
    - [ ] `arc <from point> : <mid point> : <to point>`
- [ ] `ellipse`
    - [ ] `ellipse <center> : <x axis> : <y axis>`
    - [ ] `ellipse around <block>`
### Misc
- [ ] Color expression
    - [ ] `#`
    - [ ] `RGB`
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