# ABI v0 — frozen contract

This document is the normative description of the C ABI published by
`graphos-lean-critique`. It mirrors the Graphos contract inventory
(`openspec/changes/AVI-1677-lean4-critique-replacement/contract-inventory.md`,
decision AVI-1677-D5) and adds the release/build details owned by this
repository.

Status: **ABI v0, frozen**. ABI-breaking changes require a MAJOR release and an
increment of `GRAPHOS_LEAN_CRITIQUE_ABI_VERSION`; additive changes require a
MINOR release (see [`governance.md`](governance.md)).

## Header

`include/graphos_lean_critique.h` — valid C99 and C++ (guarded by `extern "C"`).

## Version surface

| macro / symbol | value (0.2.1) | meaning |
| --- | --- | --- |
| `GRAPHOS_LEAN_CRITIQUE_ABI_VERSION` | `0` | monotonic ABI version |
| `GRAPHOS_LEAN_CRITIQUE_VERSION` | `"0.2.1"` | release SemVer string |
| `GRAPHOS_LEAN_CRITIQUE_VERSION_{MAJOR,MINOR,PATCH}` | `0,2,0` | SemVer components |
| `GRAPHOS_LEAN_CRITIQUE_SEMVER` | `201` | packed SemVer, `major*10000 + minor*100 + patch` |
| `graphos_lean_critique_abi_version(void)` | `0` | ABI version implemented by the linked library |
| `graphos_lean_critique_semver(void)` | `201` | packed SemVer of the linked release |

Consumers must check `graphos_lean_critique_abi_version() ==
GRAPHOS_LEAN_CRITIQUE_ABI_VERSION` before using the score predicate, and may
warn when `graphos_lean_critique_semver() != GRAPHOS_LEAN_CRITIQUE_SEMVER`
(stale build, not incompatible).

`VERSION` is the single source of truth; `scripts/check-version-sync.sh`
enforces agreement between `VERSION`, `lakefile.toml`, the header macros and the
Lean `versionMajor/versionMinor/versionPatch` definitions.

## Score predicate

```c
uint64_t graphos_surprise_score(uint8_t confX10,
                                uint8_t crossFiletype,
                                uint8_t crossComm,
                                uint8_t inferred);
```

| param | encoding | normalisation |
| --- | --- | --- |
| `confX10` | confidence × 10 | clamped to `0..10`; bucketed `<3`, `<8`, else |
| `crossFiletype` | `1` when endpoint file categories differ | `1` stays, everything else → `0` |
| `crossComm` | `1` when endpoints are in different communities | `1` stays, everything else → `0` |
| `inferred` | `1` when `edgeRelation == Inferred` | `1` stays, everything else → `0` |

Result: `confBonus + 2*crossFiletype + 1*crossComm + semBonus`, where

| `confBonus` | bucket | `semBonus` (inferred) |
| --- | --- | --- |
| `3` | `confX10 < 3` | `4` |
| `2` | `3 ≤ confX10 < 8` | `3` |
| `1` | `confX10 ≥ 8` | `2` |

and `semBonus = 0` when `inferred = 0`. The result is total over every
`uint8_t` input and lies in `0..10` after normalisation.

Pinned fixtures (identical in `GraphosLeanCritique/Checks.lean`,
`tests/c/abi_smoke.c` and the Graphos `AnalysisSpec`):

| confX10 | crossFiletype | crossComm | inferred | score |
| --- | --- | --- | --- | --- |
| 0 | 1 | 1 | 0 | 6 |
| 0 | 1 | 1 | 1 | 10 |
| 9 | 0 | 0 | 0 | 1 |

## Error codes

ABI v0 has no fallible entry point; invalid arguments are normalised, never
rejected. The constants are reserved for later ABI versions:

| macro | value |
| --- | --- |
| `GRAPHOS_LEAN_OK` | `0` |
| `GRAPHOS_LEAN_ERR_INVALID_ARGUMENT` | `1` |
| `GRAPHOS_LEAN_ERR_VERSION_MISMATCH` | `2` |
| `GRAPHOS_LEAN_ERR_OUT_OF_MEMORY` | `3` |

## Memory ownership

ABI v0 exchanges scalars only: nothing is allocated, nothing is owned by the
library, and no `graphos_lean_free` exists yet. A future string/array surface
must allocate on the Lean side, return pointer + length, and expose an explicit
free function; the Haskell adapter would copy into managed structures and free
before returning.

## Concurrency and runtime

Every entry point is a pure function of its arguments, reentrant, allocation
free, and safe to call concurrently. The Lean runtime does **not** need to be
initialised (`lean_initialize`) before calling them: no boxed Lean object is
touched. This is why the exported Lean functions (`*_impl`) take scalar
arguments — a nullary `@[export]` becomes a data symbol initialised only by the
Lean module initialiser — and why the version exports return **literals**:
Lean lifts a closed `UInt32` definition to a runtime global, which a caller that
never runs the initialiser would read as `0`. `scripts/check-version-sync.sh`
checks those literals against `VERSION`, and `#guard`s plus `semverImpl_eq` /
`abiVersionImpl_eq` keep them equal to the documented constants.

## Determinism and ordering

`graphos_surprise_score` is a pure function of its four parameters. Candidate
ordering (`selectTopNOn` with key `(Down score, original index)`, plus
best-candidate-per-community-pair for cross-community surprises) remains a
Haskell responsibility in ABI v0 and must be preserved by any future migration.

## Linkage inputs

The static library contains the Lean-extracted object and the C shim. Linking
it requires the Lean runtime and C++ runtime reported by
`leanc --print-ldflags`:

```
-lleancpp -lLean -lStd -lInit -lleanrt -lstdc++ -lgmp -luv -lm -ldl -pthread
```

`graphos-lean-critique.pc` carries these in `Libs.private`. gmp and libuv are
system dependencies (NixOS: `pkgs.gmp`, `pkgs.libuv`).

## Reserved additions

Non-breaking additions reserved by contract v0, to be introduced without
changing existing symbols:

- reason-mask bits `GRAPHOS_LEAN_REASON_CROSSES_FILE_TYPES` (`0x01`),
  `GRAPHOS_LEAN_REASON_SEPARATE_COMMUNITIES` (`0x02`),
  `GRAPHOS_LEAN_REASON_INFERRED_CONNECTION` (`0x04`), transported through an
  extra out-parameter in a later ABI revision.
