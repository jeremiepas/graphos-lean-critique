# graphos-lean-critique

Public open-source Lean 4 library that provides the Graphos critique
predicates as a **versioned C ABI**, linked into Graphos at build time
(`foreign import ccall`).

This is **not** a runtime-loaded plugin: the Lean definitions are compiled to C
and archived into a static library that GHC links against.

- **ABI v0**, frozen by the Graphos change
  [AVI-1677](https://github.com/jeremiepas/Graphos/tree/main/openspec/changes/AVI-1677-lean4-critique-replacement/contract-inventory.md)
- **Version 0.2.1** (see [`CHANGELOG.md`](CHANGELOG.md))
- Toolchain pinned to Lean `v4.29.1` (`lean-toolchain`)

## Status

Stage 1 bootstrap complete: the library builds, exports a stable C ABI, is
covered by executable fixtures, and is published as a versioned release.

Surface (ABI v0):

| symbol | purpose |
| --- | --- |
| `graphos_lean_critique_abi_version` | monotonic ABI version (currently `0`) |
| `graphos_lean_critique_semver` | packed release SemVer (`201` for 0.2.1) |
| `graphos_surprise_score` | numeric arm of the Haskell `surpriseScore` |

Reason strings, graph traversal, community mapping and top-N selection stay in
Haskell (`Graphos.Domain.Analysis`). Only crisp numeric predicates are
extracted; see [`docs/abi.md`](docs/abi.md) for the frozen contract.

## Quick start

```sh
# Lean side: proofs, theorems and executable fixtures
lake build

# C ABI: static library, shared library, pkg-config, smoke test
make            # libgraphoslean.a
make shared     # libgraphoslean.so
make check      # header (C99 + C++17), C + GHC ABI smoke tests, version/surface checks
make test-haskell  # link the archive into a GHC program and run the fixtures
```

On NixOS, `make LEAN_PREFIX=/nix/store/<hash>-lean4-4.29.1`; with `lean` on
`PATH` (elan) no override is needed. See [`docs/building.md`](docs/building.md).

## Consuming from Haskell / Cabal

```cabal
  Include-dirs:     <prefix>/include
  Extra-libraries:  graphoslean lean Init Std leanrt libleancpp libleanrt
  Extra-lib-dirs:   <prefix>/lib
```

or, with the shipped pkg-config file:

```sh
pkg-config --cflags --libs graphos-lean-critique
pkg-config --static --libs graphos-lean-critique   # Lean runtime + gmp + uv
```

Always compare `graphos_lean_critique_abi_version()` with
`GRAPHOS_LEAN_CRITIQUE_ABI_VERSION` before calling into the library, and compare
`graphos_lean_critique_semver()` with `GRAPHOS_LEAN_CRITIQUE_SEMVER` to detect a
stale build.

## Releases

Each `vX.Y.Z` tag publishes a source-less, build-ready bundle:

```
graphos-lean-critique-X.Y.Z-linux-<arch>.tar.gz
└── include/graphos_lean_critique.h
    lib/libgraphoslean.a
    lib/libgraphoslean.so
    lib/pkgconfig/graphos-lean-critique.pc
    VERSION  LICENSE  README.md  CHANGELOG.md  docs/
```

See [`docs/releasing.md`](docs/releasing.md) and
[`docs/governance.md`](docs/governance.md) for the versioning, ABI and
deprecation policy.

## Repository layout

```
GraphosLeanCritique/Critique.lean   extracted ABI predicates (only this module → C)
GraphosLeanCritique/Theorems.lean   proof-only spec theorems
GraphosLeanCritique/Checks.lean     #guard executable fixtures (build-time)
src/abi_shim.c                      stable public C ABI layer
include/graphos_lean_critique.h     public header
tests/c/                            ABI smoke test + header compile check
tests/haskell/Consumer.hs           GHC consumer (the linking side of the bridge)
scripts/                            version-sync and surface checks
docs/                               ABI contract, build, release, governance
```

## License

MIT — see [`LICENSE`](LICENSE). Contributions follow
[`CONTRIBUTING.md`](CONTRIBUTING.md) and [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
