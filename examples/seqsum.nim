import std/syncio
var s = @[1, 2, 3, 4, 5]
var total = 0
for x in s:
  total = total + x
echo total
