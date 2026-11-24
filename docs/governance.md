# Governance

This repository is a public open-source companion to Graphos. Its ABI is a
contract with a downstream consumer, so changes follow a stricter process than
a normal library.

## Versioning (SemVer)

`VERSION` is the single source of truth.

| change | version bump | `GRAPHOS_LEAN_CRITIQUE_ABI_VERSION` |
| --- | --- | --- |
| new entry point, new optional out-parameter, new macro | MINOR | unchanged |
| changed meaning, removed/renamed symbol, changed signature, changed normalisation | MAJOR | incremented |
| bug fix that restores documented behaviour, docs, CI | PATCH | unchanged |

Rules:

- A released version is immutable: never retag, never rewrite a published
  release.
- Additive symbols are only safe once the downstream consumer has been checked:
  ABI v0 keeps reason generation in Haskell, so new output parameters wait for a
  deliberate ABI revision.
- `scripts/check-version-sync.sh` fails CI when `VERSION`, `lakefile.toml`, the
  header macros and the Lean `versionMajor/Minor/Patch` definitions disagree.
- The ABI version never decreases; `graphos_lean_critique_abi_version()` must
  equal `GRAPHOS_LEAN_CRITIQUE_ABI_VERSION` for a library to be considered
  compatible.

## ABI compatibility policy

- The public surface is exactly what `include/graphos_lean_critique.h` declares.
  Raw `@[export]` names are internal (`*_impl`) and may change.
- Semantics are normative: `docs/abi.md` plus the pinned fixtures in
  `GraphosLeanCritique/Checks.lean` and `tests/c/abi_smoke.c`.
- A change to the normalisation rules (confidence clamping, `0/1` flags) is
  ABI-breaking even when it only affects unusual inputs.
- Compile-time linkage only: no runtime plugin loading, no dylib hot-swap.

## Deprecation process

1. Announce the deprecation in `CHANGELOG.md` under `Deprecated` and in the
   header comment of the affected symbol.
2. Keep the symbol working for at least one MINOR release.
3. Remove it only in the next MAJOR release, together with the ABI version bump
   and a `Removed` changelog entry.

## Releases

Tag-driven, automated by `.github/workflows/release.yml` (see
[`releasing.md`](releasing.md)). Every release publishes the header, static and
shared libraries, the pkg-config file, and the docs bundle. The release notes
list ABI impact and any deprecations.

## Issue tracker

GitHub Issues on this repository is the public tracker. Bug reports must include
the affected version (`graphos_lean_critique_semver()` output or the release
tag), the ABI version, and a minimal reproducer. Security reports follow
[`SECURITY.md`](../SECURITY.md) instead of the public tracker.

## Change review

- `main` is protected: changes land through pull requests.
- Every extracted predicate needs a spec theorem (see
  `GraphosLeanCritique/Theorems.lean`) and a `#guard` fixture.
- CI must be green: `lake build`, no `sorry`/`admit`, header valid as C99 and
  C++17, ABI smoke test, version sync.

## Relationship to Graphos

This repository owns the Lean project, the ABI and its releases. The Graphos
repository (AVI-1677, decisions D0–D7) owns the FFI adapter, Cabal linkage,
parity tests and the rollout flags, and pins a released version of this library.
No Graphos source is duplicated here, and no Graphos repository is created for
the bridge.
