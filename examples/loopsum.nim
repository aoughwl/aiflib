import std/syncio
var total = 0
for i in 0 ..< 10:
  total = total + i
echo total
