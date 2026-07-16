import std/syncio
var s: seq[int] = @[]
var i = 0
while i < 1000:
  s.add(i)
  i = i + 1
echo s.len
echo s[0]
echo s[999]
var sum = 0
for x in s: sum = sum + x
echo sum
