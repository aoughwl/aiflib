# The aiflib runtime contract

This is the precise contract `aiflib` implements so a post-`hexer` `.c.nif`
links natively. Everything is derived from the real backend output of the local
nimony toolchain (`lib/std/system/*`, `lib/std/syncio.nim`).

## How linking works

Nimony compiles each module to its own `.c.nif` and links them all; the
`system`/`syncio` modules become `.c.nif` too. aiflib **replaces** those two
modules, so only the *main* module's `.c.nif` is compiled — its references into
`system`/`syncio` are satisfied by the aiflib C runtime.

Those references are **content-addressed**: `write.0.syn1lfpjv` is
`write`, overload-disambiguator `0`, from the module whose hash is `syn1lfpjv`.
aifc mangles that to the C identifier `write_0_syn1lfpjv`. The main module's own
symbols carry an *empty* hash (`main.0.`), so:

> an undefined runtime extern is exactly a referenced symbol atom
> `base.disamb.HASH` with a **non-empty** `HASH`.

`bin/aiflib-cc` collects those, maps each `base` via `runtime/runtime-map.js`
onto a hash-independent aiflib entry point, and injects a shim right after
aifc's C prelude:

```c
/* ---- aiflib shim (generated) ---- */
typedef struct { NI fullLen_0; NI rc_0; NI capImpl_0; NC8* data_0; } Aiflib_LongString;
typedef struct { NU bytes_0; Aiflib_LongString* more_0; } Aiflib_string;
typedef Aiflib_string string_0_sysvq0asl;      /* type aliased by name        */
#define write_0_syn1lfpjv aiflib_write_string  /* proc/global aliased by macro */
#define stdout_0_syn1lfpjv aiflib_stdout
```

Field names (`bytes_0`, `fullLen_0`, …) are **hash-independent** — they come from
nimony field names plus a `.disamb` — so aiflib pins them; only the type/proc
*symbol* names carry the module hash and are bridged by the shim.

## Type layouts

| type | layout | mirrors |
|---|---|---|
| `string` | `{ NU bytes; LongString* more; }` (16 B) | `system/basic_types.nim` |
| `LongString` | `{ NI fullLen; NI rc; NI capImpl; NC8* data; }` | ″ (see note) |
| `seq[T]` | `{ NI len; void* data; }` (16 B) | `system/seqimpl.nim` |
| `File` | `{ NI fd; NU flags; }` (nimNativeIo model) | `syncio.nim` |

**Note on `LongString.data`.** nimony declares it `UncheckedArray[char]` (an
inline flexible array at offset 24). aiflib uses a **pointer** instead, because
(a) that is exactly what aifc emits for a string-literal const —
`(LongString){ .data_0 = "hello" }` stores a pointer to real storage, whereas a
flexible-array compound literal reserves *no* space and overflows — and (b) it
lets a heap string be a single allocation (`header + data + NUL`, `data`
pointing just past the header) so one `free` releases it. The tradeoff: a
program that **indexes** into a string (`s[i]`) inlines nimony's flexible-array
`rawData` and would read the pointer bytes as chars. No aiflib caller indexes;
supporting `s[i]` is future work (either match the inline layout or teach aifc to
emit indexing through the runtime).

## SSO string encoding (`stringimpl.nim`)

`slen` = low byte of `bytes` (little-endian). Tiers:

| slen | tier | data | length |
|---|---|---|---|
| ≤ 7 | short | inline, `bytes` byte 1.. | slen |
| 8–14 | medium | inline across `bytes`+`more` | slen |
| 255 | long (heap) | `more->data`, refcounted `more->rc` | `more->fullLen` |
| 254 | static (literal) | `more->data`, never freed | `more->fullLen` |

`aiflib_str_from_bytes(p, n)` builds a fresh string: inline when `n ≤ 14`, else a
heap `LongString` (slen 255, `rc = 0`).

## ARC (`arcops.nim`)

Single-threaded; `rc` stores `refcount - 1`, so `0` == unique.

- `arcInc(rc)` → `++rc`
- `arcDec(rc)` → `rc == 0 ? true (free) : (--rc, false)`
- `arcIsUnique(rc)` → `rc == 0`

## Coverage

Symbols the runtime currently provides (see `runtime/runtime-map.js`):

| area | symbols |
|---|---|
| init | `ini` (no-op) |
| io | `write`(string/char/int/uint/bool/float), `stdout`/`stderr`/`stdin`, `nimFlushStdStreams` |
| strings | `&`, `$`(int/uint/bool), `add`(char/str), `len`, `=destroy`/`=copy`/`=dup`/`=wasMoved` (string) |
| memory | `alloc`/`alloc0`/`realloc`/`dealloc`/`allocatedSize`, `allocFixed`/`deallocFixed` |
| arc | `arcInc`/`arcDec`/`arcIsUnique` |
| panics | `panic`, `nimIcheckB` (bounds), `oomHandler` |

**Overload resolution.** `write`, `$`, `add` and the `=hooks` are overloaded by
one name. `aiflib-cc` picks the target from the call's argument **type**, read
from the IR: literal shape, the variable's declaration in the same module, or
the type a typed expression node carries. `write` additionally falls back to a
verified disambiguator table (`0`=string, `1`=bool, `2`=int, `7`=char) for
arguments whose type can't be read (field accesses, calls). Lifecycle hooks that
reach the linker as externs are string hooks (seq/`ref` hooks are monomorphised
into the program), so an unclassifiable one resolves to the string hook.

Anything unmapped is printed as a coverage gap and the build fails — the runtime
is never silently stubbed.

## aifc dependencies

aiflib links `aifc`'s printed C. Building the suite exercised (and fixed
upstream in `aifc`) three printer completeness points:

- `(ovf)` — read the overflow flag `(keepovf …)` sets (needed by seq bounds).
- prototypes for **inline** procs — a monomorphised `static inline` seq helper
  called before its definition otherwise got a conflicting implicit declaration.
- **forward declarations** for object/union structs — a `ref` typedef that
  points at a struct defined later in source order now resolves.

## Not yet covered (future work)

String indexing (`s[i]`, inline `rawData`); exceptions across the `eraiser`
error-code path beyond `panic`; float `$`; the aowl-source `system` module
(Phase 2) that would replace this hand-written C with code compiled *through*
the stack.
