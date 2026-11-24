-- Graphos Lean critique predicates, exported as a C ABI.
--
-- Only crisp numeric predicates land here. Natural-language reasons and graph
-- traversal stay on the Haskell side (see Graphos.Domain.Analysis in the
-- Graphos repository).
--
-- The public C ABI is *not* the raw `@[export]` surface: `src/abi_shim.c`
-- defines the stable entry points declared in `include/graphos_lean_critique.h`
-- and forwards to the `*_impl` exports below. Lean cannot export a true
-- zero-argument C function (a nullary `@[export]` becomes a writable data
-- symbol that is only initialised by the Lean module initialiser), so every
-- exported function here takes one scalar argument.

/-! ## ABI version -/

/-- ABI version reported by `graphos_lean_critique_abi_version`.
    Keep in sync with `GRAPHOS_LEAN_CRITIQUE_ABI_VERSION` in the C header. -/
def abiVersion : UInt32 := 0

@[export graphos_lean_critique_abi_version_impl]
def abiVersionImpl (_unit : UInt8) : UInt32 := abiVersion

/-! ## Package semver -/

/-- SemVer components of this release. Keep in sync with `VERSION`, the
    `GRAPHOS_LEAN_CRITIQUE_VERSION_*` macros and `lakefile.toml`. -/
def versionMajor : UInt32 := 0
def versionMinor : UInt32 := 1
def versionPatch : UInt32 := 0

/-- Packed SemVer, `major * 10000 + minor * 100 + patch`, so a scalar ABI can
    carry the full release version. For 0.1.0 this is `100`. -/
def packedSemver : UInt32 :=
  versionMajor * 10000 + versionMinor * 100 + versionPatch

@[export graphos_lean_critique_semver_impl]
def semverImpl (_unit : UInt8) : UInt32 := packedSemver

/-! ## Score predicate (ABI v0) -/

/-- Confidence bucket score, matching the Haskell:
    c < 0.3  -> 3, c < 0.8 -> 2, otherwise -> 1.
    `confX10` is confidence multiplied by ten (0..10) so the ABI stays integer. -/
def confBonus (confX10 : UInt8) : UInt64 :=
  if confX10 < 3 then 3
  else if confX10 < 8 then 2
  else 1

/-- Cross-file-type bonus (2) when the two endpoints differ in file category. -/
def crossFiletypeBonus (crossFiletype : UInt8) : UInt64 :=
  if crossFiletype == 1 then 2 else 0

/-- Cross-community bonus (1) when the endpoints live in different communities. -/
def crossCommunityBonus (crossComm : UInt8) : UInt64 :=
  if crossComm == 1 then 1 else 0

/-- Semantic bonus for an inferred edge: round (confBonus * 1.5).
    Haskell uses `round @Double`, which is round-half-to-even; the three
    possible inputs give 4, 3, and 2 respectively. -/
def semBonus (inferred : UInt8) (cb : UInt64) : UInt64 :=
  if inferred == 1 then
    if cb == 3 then 4 else if cb == 2 then 3 else 2
  else 0

@[export graphos_surprise_score_impl]
def surpriseScore (confX10 : UInt8) (crossFiletype : UInt8) (crossComm : UInt8) (inferred : UInt8) : UInt64 :=
  let cb := confBonus confX10
  cb + crossFiletypeBonus crossFiletype + crossCommunityBonus crossComm + semBonus inferred cb
