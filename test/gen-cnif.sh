#!/usr/bin/env bash
# gen-cnif.sh <src.nim> <out.c.nif> — compile a .nim to its main-module .c.nif
# using the local nimony toolchain, then copy the hashed artifact to a clean path.
set -euo pipefail
NIMONY="${AIFLIB_NIMONY:-$HOME/nimony/bin/nimony}"
src="$1"; out="$2"
base="$(basename "$src" .nim)"
nc="$(mktemp -d)"
"$NIMONY" --nimcache:"$nc" c "$src" >/dev/null 2>"$nc/err" || { cat "$nc/err" >&2; exit 1; }
# The main module is the one carrying `exportc "main"`; module .c.nifs are hash-named.
art="$(grep -l 'exportc "main"' "$nc"/*/*.c.nif 2>/dev/null | head -1)"
[ -n "$art" ] || { echo "gen-cnif: no main .c.nif produced for $src" >&2; cat "$nc/err" >&2; exit 1; }
cp "$art" "$out"
rm -rf "$nc"
echo "$out"
