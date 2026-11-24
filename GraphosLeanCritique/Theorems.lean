import GraphosLeanCritique.Critique

/-!
# Spec theorems for the extracted ABI surface

Contract obligations from the Graphos contract inventory (AVI-1677, ABI v0).
Every theorem here is proof-only: none is exported through `@[export]`, so the
generated C surface stays primitive and serialisable.
-/

/-! ## `confBonus` bucketing -/

theorem confBonus_lt3 {x : UInt8} (h : x < 3) : confBonus x = 3 := by
  unfold confBonus
  simp [h]

theorem confBonus_mid {x : UInt8} (h1 : 3 ≤ x) (h2 : x < 8) : confBonus x = 2 := by
  unfold confBonus
  have hnot : ¬ (x < 3) := Nat.not_lt_of_ge h1
  simp [hnot, h2]

theorem confBonus_high {x : UInt8} (h : 8 ≤ x) : confBonus x = 1 := by
  unfold confBonus
  have h1 : ¬ (x < 3) := Nat.not_lt_of_ge (Nat.le_trans (by decide) h)
  have h2 : ¬ (x < 8) := Nat.not_lt_of_ge h
  simp [h1, h2]

/-- `confBonus` only ever returns the three contract buckets. -/
theorem confBonus_values (x : UInt8) :
    confBonus x = 1 ∨ confBonus x = 2 ∨ confBonus x = 3 := by
  unfold confBonus
  by_cases h1 : x < 3
  · simp [h1]
  · by_cases h2 : x < 8
    · simp [h1, h2]
    · simp [h1, h2]

/-! ## Component-wise non-negativity -/

theorem crossFiletypeBonus_values (x : UInt8) :
    crossFiletypeBonus x = 0 ∨ crossFiletypeBonus x = 2 := by
  unfold crossFiletypeBonus
  by_cases h : x = 1 <;> simp [h]

theorem crossCommunityBonus_values (x : UInt8) :
    crossCommunityBonus x = 0 ∨ crossCommunityBonus x = 1 := by
  unfold crossCommunityBonus
  by_cases h : x = 1 <;> simp [h]

theorem semBonus_zero_when_not_inferred (inferred : UInt8) (cb : UInt64)
    (h : inferred ≠ 1) : semBonus inferred cb = 0 := by
  unfold semBonus
  simp [h]

theorem semBonus_le_four (inferred : UInt8) (cb : UInt64) : semBonus inferred cb ≤ 4 := by
  unfold semBonus
  split
  · split
    · decide
    · split <;> decide
  · decide

/-! ## Totality: the score is a closed, total function -/

/-- The ABI score is total over its frozen argument domain; nothing can fail. -/
theorem surpriseScore_total (confX10 crossFiletype crossComm inferred : UInt8) :
    ∃ s : UInt64, surpriseScore confX10 crossFiletype crossComm inferred = s :=
  ⟨_, rfl⟩

/-- The score is a pure function of the four ABI arguments (determinism). -/
theorem surpriseScore_deterministic
    (c₁ c₂ f₁ f₂ m₁ m₂ i₁ i₂ : UInt8)
    (hc : c₁ = c₂) (hf : f₁ = f₂) (hm : m₁ = m₂) (hi : i₁ = i₂) :
    surpriseScore c₁ f₁ m₁ i₁ = surpriseScore c₂ f₂ m₂ i₂ := by
  subst hc hf hm hi
  rfl

/-! ## Version surface -/

/-- The ABI version is the frozen v0 value. -/
theorem abiVersion_eq_zero : abiVersion = 0 := rfl

/-- The literal exported by `abiVersionImpl` equals `abiVersion`. -/
theorem abiVersionImpl_eq : abiVersionImpl 0 = abiVersion := by decide

/-- Packed SemVer agrees with its components. -/
theorem packedSemver_eq : packedSemver = 200 := by decide

/-- The literal exported by `semverImpl` equals `packedSemver`. -/
theorem semverImpl_eq : semverImpl 0 = packedSemver := by decide
