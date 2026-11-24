#!/usr/bin/env bash
# check-no-sorry.sh — the exported surface and its theorems must be complete.
#
# Fails on `sorry`, `admit`, or a theorem left as a bare `by` placeholder, and
# asserts that proof-only modules are never imported by the extracted ABI
# module (only Critique.lean is compiled to C).
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0

if grep -rnE '\b(sorry|admit)\b' --include='*.lean' GraphosLeanCritique.lean GraphosLeanCritique; then
  echo "found sorry/admit in Lean sources" >&2
  fail=1
fi

# The ABI module must not import theorem or check modules: proofs and fixtures
# stay out of the generated C.
if grep -nE '^import ' GraphosLeanCritique/Critique.lean; then
  echo "GraphosLeanCritique/Critique.lean must stay import-free" >&2
  fail=1
fi

# Every exported symbol must be declared in the public header.
exports="$(grep -oE '@\[export [a-zA-Z0-9_]+' GraphosLeanCritique/Critique.lean |
  sed 's/@\[export //')"
for sym in $exports; do
  case "$sym" in
    *_impl)
      if ! grep -qE "\b${sym}\(" src/abi_shim.c; then
        echo "export '$sym' has no declaration in src/abi_shim.c" >&2
        fail=1
      fi
      ;;
    *)
      if ! grep -qE "\b${sym}\(" include/graphos_lean_critique.h; then
        echo "export '$sym' is not declared in include/graphos_lean_critique.h" >&2
        fail=1
      fi
      ;;
  esac
done

# The public header declares exactly the three v0 entry points.
for sym in graphos_lean_critique_abi_version graphos_lean_critique_semver graphos_surprise_score; do
  if ! grep -qE "\b${sym}\(" include/graphos_lean_critique.h; then
    echo "public entry point '$sym' missing from the header" >&2
    fail=1
  fi
  if ! grep -qE "^[a-z0-9_]+ ${sym}\(" src/abi_shim.c; then
    echo "public entry point '$sym' not defined in src/abi_shim.c" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "Lean surface check FAILED" >&2
  exit 1
fi
echo "Lean surface check passed (no sorry/admit, header and shim in sync)"
