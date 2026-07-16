import std/syncio
proc mk(n: int): seq[int] =
  result = @[]
  var i = 0
  while i < n:
    result.add(i*i)
    i = i + 1
let s = mk(5)
echo s.len
echo s[4]
