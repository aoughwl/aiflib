import std/syncio
var m: seq[seq[int]] = @[]
m.add(@[1,2])
m.add(@[3,4,5])
echo m.len
echo m[1].len
echo m[1][2]
