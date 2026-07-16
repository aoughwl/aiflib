import std/syncio
let s = "hello"
for c in s:
  echo c
var n = 0
for c in "abcdefghijklmnopqrstuvwxyz":
  n = n + 1
echo n
