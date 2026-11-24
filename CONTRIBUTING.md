# Contributing

This project is the public Lean 4 companion to Graphos. Keep the extracted ABI
primitives serialisable and free of proof-only definitions. Theorems are
required for every extracted predicate (see the Graphos lean-proof-methodology).

## Ground rules

- Only `GraphosLeanCritique/Critique.lean` is compiled to C. It must stay
  import-free, and every `@[export]` must either be a `*_impl` declared in
  `src/abi_shim.c` or a public entry point declared in the header.
- Every new predicate needs: a spec theorem in
  `GraphosLeanCritique/Theorems.lean`, a `#guard` fixture in
  `GraphosLeanCritique/Checks.lean`, and a matching assertion in
  `tests/c/abi_smoke.c`.
- No `sorry`, `admit`, `native_decide`-only proofs on the exported surface, or
  axioms beyond Lean's standard ones.
- Changes to the public surface follow [`docs/governance.md`](docs/governance.md):
  additive → MINOR, breaking → MAJOR plus an ABI version bump.

## Before opening a pull request

```sh
lake build
make check
git diff --exit-code VERSION lakefile.toml include/   # version bump is deliberate
```

CI runs the same commands plus the release-bundle build. A pull request must
state its ABI impact explicitly in the description.

## Commit style

Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `test:`), scoped by
module where useful, e.g.

```
fix(abi): export abi version as a function, not a data symbol
```
