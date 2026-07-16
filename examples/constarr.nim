import std/syncio
const primes = [2, 3, 5, 7, 11]
echo primes[0]
echo primes[4]
var s = 0
for p in primes: s = s + p
echo s
