# graphos-lean-critique

Public open-source Lean 4 library that provides Graphos critique predicates as a
**versioned C ABI**, linked into Graphos at build time (`foreign import ccall`).

This is **not** a runtime-loaded plugin: the Lean definitions are compiled to C
and archived into a static library that GHC links against.

## Status

Stage 1 bootstrap. Current surface: `graphos_surprise_score` (Stage 0 spike),
the numeric arm of `Graphos.Domain.Analysis.surpriseScore`.

## Toolchain

- Lean 4.29.1 (pinned via `lean-toolchain` / elan)
- NixOS users: `/nix/store/cwilxazl2n8f59lksc4xihx560485ci8-lean4-4.29.1/bin`

## Build the ABI (NixOS)

```sh
make ABI=1        # prints the recipe if you don't have make installed
lean -c Critique.c GraphosLeanCritique/Critique.lean
leanc -c Critique.c -o Critique.o
ar rcs libgraphoslean.a Critique.o
```

See `docs/building.md`.

## Versioning

ABI version is reported at runtime by `graphos_lean_critique_abi_version()` and
also exposed as `GRAPHOS_LEAN_CRITIQUE_ABI_VERSION` in the header. Package
versions follow SemVer; ABI-breaking changes require a major bump.
