import std/syncio
var i = 0
var acc = 1
while i < 5:
  acc = acc * 2
  i = i + 1
echo acc
