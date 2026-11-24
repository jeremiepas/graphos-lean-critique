# Changelog

All notable changes to `graphos-lean-critique` are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) together
with the ABI policy in [`docs/governance.md`](docs/governance.md).

## [Unreleased]

## [0.1.0] - 2026-11-24

First published release. Stage 1 bootstrap of the public OSS bridge for Graphos
AVI-1677.

### Added

- Stable C ABI layer `src/abi_shim.c` defining the public entry points declared
  in `include/graphos_lean_critique.h`.
- `graphos_lean_critique_semver()` plus `GRAPHOS_LEAN_CRITIQUE_VERSION`,
  `_VERSION_{MAJOR,MINOR,PATCH}` and packed `GRAPHOS_LEAN_CRITIQUE_SEMVER`
  macros, so consumers can detect a stale build as well as an incompatible one.
- Explicit ABI v0 argument normalisation in the shim (confidence clamped to
  `0..10`, flags other than `1` treated as false).
- Executable `#guard` fixtures in `GraphosLeanCritique/Checks.lean` and spec
  theorems for bucketing, component values, determinism, totality and the
  version surface in `GraphosLeanCritique/Theorems.lean`.
- C ABI smoke test (`tests/c/abi_smoke.c`), header compile checks for C99 and
  C++17, version-sync and Lean-surface scripts.
- `Makefile` targets for static library, shared library, pkg-config, tests,
  release bundle and install; toolchain autodetection (elan on `PATH` or Nix
  store).
- CI (`lake build`, no `sorry`, header checks, ABI smoke test) and tag-driven
  release workflow publishing the bundle.
- Documentation: `docs/abi.md` (frozen contract), `docs/building.md`,
  `docs/releasing.md`, `docs/governance.md`, `SECURITY.md`.

### Fixed

- `graphos_lean_critique_abi_version` was exported as a Lean nullary definition
  and therefore emitted as a writable **data** symbol initialised only by the
  Lean module initialiser; the C header declared it as a function, so calling it
  from `foreign import ccall` was undefined behaviour. The version query is now
  a real C function in the shim forwarding to `..._abi_version_impl`.
- Only `GraphosLeanCritique/Critique.lean` is extracted to C, keeping theorems
  and fixtures out of the generated ABI surface (enforced by CI).

[Unreleased]: https://github.com/jeremiepas/graphos-lean-critique/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/jeremiepas/graphos-lean-critique/releases/tag/v0.1.0
