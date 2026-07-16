import std/syncio
type Person = ref object
  name: string
  age: int
var p = Person(name: "Alice", age: 30)
echo p.name
echo p.age
