import std/syncio
type Node = ref object
  val: int
var n = Node(val: 7)
echo n.val
