# Building graphos-lean-critique

## Prerequisites

- Lean 4 (pinned by `lean-toolchain`; install via elan)
- A C compiler (gcc/clang)
- `ar`

## ABI shared/static library

```sh
lean -c Critique.c GraphosLeanCritique/Critique.lean
leanc -c Critique.c -o Critique.o
ar rcs libgraphoslean.a Critique.o
```

Linker inputs (from `leanc --print-ldflags`): `libInit`, `libStd`, `libLean`,
`libleanrt`, `libleancpp`, `libgmp`, `libuv`, `stdc++`, `m`, `dl`, `pthread`.

## Linking from Haskell (Cabal)

```cabal
Include-dirs:      include
Extra-libraries:   graphoslean lean Init Std leanrt libleancpp libleanrt
Extra-lib-dirs:    <path to the .a above>
```
