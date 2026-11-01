import GraphosLeanCritique.Critique

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

theorem crossFiletypeBonus_values (x : UInt8) :
    crossFiletypeBonus x = 0 ∨ crossFiletypeBonus x = 2 := by
  unfold crossFiletypeBonus
  by_cases h : x = 1 <;> simp [h]

theorem semBonus_zero_when_not_inferred (inferred : UInt8) (cb : UInt64)
    (h : inferred ≠ 1) : semBonus inferred cb = 0 := by
  unfold semBonus
  simp [h]
