import std/syncio
type Buf = object
  data: array[3, int]
var b: Buf
b.data[0] = 100
b.data[1] = 200
b.data[2] = 300
echo b.data[0] + b.data[1] + b.data[2]
