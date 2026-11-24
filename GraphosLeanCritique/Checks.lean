import GraphosLeanCritique.Critique

/-!
# Executable ABI fixture checks

`#guard` is elaborated at build time, so `lake build` fails if any pinned
fixture, version value, or contract invariant drifts. These are the fixture
pairs frozen by the Graphos contract inventory (AVI-1677, ABI v0):

  (confX10, crossFiletype, crossComm, inferred) -> expected score
  (0, 1, 1, 0) -> 6
  (0, 1, 1, 1) -> 10
  (9, 0, 0, 0) -> 1

Keep these in sync with `tests/c/abi_smoke.c`; the C test exercises the public
shim (argument normalisation included), this file exercises the Lean predicate.
-/

/-! ## Score fixtures -/

#guard surpriseScore 0 1 1 0 == 6
#guard surpriseScore 0 1 1 1 == 10
#guard surpriseScore 9 0 0 0 == 1

/-! ## Bucket boundaries -/

#guard confBonus 0 == 3
#guard confBonus 2 == 3
#guard confBonus 3 == 2
#guard confBonus 7 == 2
#guard confBonus 8 == 1
#guard confBonus 255 == 1

/-! ## Component bonuses -/

#guard crossFiletypeBonus 1 == 2
#guard crossFiletypeBonus 0 == 0
#guard crossFiletypeBonus 2 == 0
#guard crossCommunityBonus 1 == 1
#guard crossCommunityBonus 0 == 0
#guard semBonus 1 3 == 4
#guard semBonus 1 2 == 3
#guard semBonus 1 1 == 2
#guard semBonus 0 3 == 0

/-! ## Totality over unnormalised input (the C shim does the clamping) -/

#guard surpriseScore 255 7 7 9 == 1
#guard surpriseScore 255 0 0 0 == 1

/-! ## Version constants -/

#guard abiVersion == 0
#guard versionMajor == 0
#guard versionMinor == 1
#guard versionPatch == 0
#guard packedSemver == 100
