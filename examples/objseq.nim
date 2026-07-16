import std/syncio
type Bag = object
  items: seq[int]
var b = Bag(items: @[1,2,3])
b.items.add(4)
echo b.items.len
var t = 0
for x in b.items: t = t + x
echo t
