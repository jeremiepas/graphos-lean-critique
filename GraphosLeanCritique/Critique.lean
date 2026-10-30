-- Graphos Lean critique predicates, exported as a C ABI.
--
-- Only crisp numeric predicates land here. Natural-language reasons and graph
-- traversal stay on the Haskell side (see Graphos.Domain.Analysis).

def confBonus (confX10 : UInt8) : UInt64 :=
  if confX10 < 3 then 3
  else if confX10 < 8 then 2
  else 1

def crossFiletypeBonus (crossFiletype : UInt8) : UInt64 :=
  if crossFiletype == 1 then 2 else 0

def crossCommunityBonus (crossComm : UInt8) : UInt64 :=
  if crossComm == 1 then 1 else 0

def semBonus (inferred : UInt8) (cb : UInt64) : UInt64 :=
  if inferred == 1 then
    if cb == 3 then 4 else if cb == 2 then 3 else 2
  else 0

@[export graphos_surprise_score]
def surpriseScore (confX10 : UInt8) (crossFiletype : UInt8) (crossComm : UInt8) (inferred : UInt8) : UInt64 :=
  let cb := confBonus confX10
  cb + crossFiletypeBonus crossFiletype + crossCommunityBonus crossComm + semBonus inferred cb

@[export graphos_lean_critique_abi_version]
def abiVersion : UInt32 := 0
