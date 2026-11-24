# Changelog

All notable changes to `graphos-lean-critique` are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) together
with the ABI policy in [`docs/governance.md`](docs/governance.md).

## [Unreleased]

## [0.2.0] - 2026-11-24

Stage 1 completion (Graphos AVI-1677, tasks 1.3 and 1.4): a stable C ABI,
versioned release bundles, CI, docs and governance. ABI stays **v0**; the
surface only grows, hence a MINOR bump.

### Added

- Stable C ABI layer `src/abi_shim.c` defining the public entry points declared
  in `include/graphos_lean_critique.h`, with all Lean exports renamed to
  `*_impl` scalar functions.
- `graphos_lean_critique_semver()` plus `GRAPHOS_LEAN_CRITIQUE_VERSION`,
  `_VERSION_{MAJOR,MINOR,PATCH}` and packed `GRAPHOS_LEAN_CRITIQUE_SEMVER`
  macros, so consumers can detect a stale build as well as an incompatible one.
- Explicit ABI v0 argument normalisation in the shim (confidence clamped to
  `0..10`, flags other than `1` treated as false): the score is total over every
  `uint8_t` input.
- Executable `#guard` fixtures in `GraphosLeanCritique/Checks.lean`, and spec
  theorems for bucketing, component values, determinism, totality and the
  version surface in `GraphosLeanCritique/Theorems.lean`.
- C ABI smoke test over the whole input domain (`tests/c/abi_smoke.c`), header
  compile checks as C99 and C++17, version-sync and Lean-surface scripts.
- `Makefile` targets for the static library, shared library, pkg-config, tests,
  release bundle and install; toolchain autodetection (elan on `PATH` or a Nix
  store path).
- CI job gates (`lake build` with warnings as errors, no `sorry`, header checks,
  ABI smoke test, pkg-config validation, bundle build) and a tag-driven release
  workflow that re-verifies the extracted bundle before publishing.
- Documentation: `docs/abi.md` (frozen contract), `docs/building.md`,
  `docs/releasing.md`, `docs/governance.md`, `SECURITY.md`.

### Fixed

- `graphos_lean_critique_abi_version` was a Lean nullary definition and
  therefore a writable **data** symbol initialised only by the Lean module
  initialiser, while the header declared it as a function; calling it through
  `foreign import ccall` was undefined behaviour. It is now a real C function in
  the shim, forwarding to `graphos_lean_critique_abi_version_impl`.
- Only `GraphosLeanCritique/Critique.lean` is extracted to C, keeping theorems
  and fixtures out of the generated ABI surface (enforced in CI).
- `.gitignore` no longer swallows `src/*.c` and `tests/c/*.c`.

## [0.1.0] - 2026-10-30

Stage 1 bootstrap release (Graphos AVI-1677, tasks 1.1 and 1.2).

### Added

- Public repository with MIT license, Lean `v4.29.1` pinned via `lean-toolchain`
  and `lakefile.toml`.
- First exported surface: `graphos_surprise_score` (ABI v0 numeric predicate)
  and `graphos_lean_critique_abi_version`.
- Theorem gates for the `confBonus` buckets in `GraphosLeanCritique/Theorems`.
- `Makefile` producing `libgraphoslean.a`, a minimal CI workflow, and initial
  build/link documentation.

[Unreleased]: https://github.com/jeremiepas/graphos-lean-critique/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/jeremiepas/graphos-lean-critique/releases/tag/v0.2.0
[0.1.0]: https://github.com/jeremiepas/graphos-lean-critique/releases/tag/v0.1.0
