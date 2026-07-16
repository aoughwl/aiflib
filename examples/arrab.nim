import std/syncio
var a: array[2..5, int]
a[2] = 100
a[3] = 200
a[4] = 300
a[5] = 400
var i = 4
echo a[i]
echo a[2]
