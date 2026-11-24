#!/usr/bin/env bash
# check-version-sync.sh — enforce one version in every place that publishes it.
#
# VERSION is the single source of truth. This script fails when any of the
# following disagree with it:
#   - lakefile.toml                   (package version)
#   - include/graphos_lean_critique.h (GRAPHOS_LEAN_CRITIQUE_VERSION + components)
#   - GraphosLeanCritique/Critique.lean (versionMajor/Minor/Patch)
#   - the ABI version in the header and in Critique.lean
set -euo pipefail

cd "$(dirname "$0")/.."

version="$(tr -d '[:space:]' < VERSION)"
major="${version%%.*}"
rest="${version#*.}"
minor="${rest%%.*}"
patch="${rest#*.}"

fail=0
note() { printf '  %-52s %s\n' "$1" "$2"; }
err() { echo "version mismatch: $*" >&2; fail=1; }

echo "VERSION = $version"

lake="$(sed -n 's/^version = "\([^"]*\)"/\1/p' lakefile.toml)"
if [ "$lake" != "$version" ]; then err "lakefile.toml has '$lake'"; fi
note "lakefile.toml" "$lake"

header_version="$(sed -n 's/^#define GRAPHOS_LEAN_CRITIQUE_VERSION "\([^"]*\)"/\1/p' include/graphos_lean_critique.h)"
if [ "$header_version" != "$version" ]; then err "header VERSION has '$header_version'"; fi
note "header GRAPHOS_LEAN_CRITIQUE_VERSION" "$header_version"

for part in MAJOR MINOR PATCH; do
  want_var="major"
  [ "$part" = MINOR ] && want_var="minor"
  [ "$part" = PATCH ] && want_var="patch"
  want="${!want_var}"
  got="$(sed -n "s/^#define GRAPHOS_LEAN_CRITIQUE_VERSION_${part} \([0-9]*\)/\1/p" include/graphos_lean_critique.h)"
  if [ "$got" != "$want" ]; then err "header ${part} has '$got', want '$want'"; fi
  note "header GRAPHOS_LEAN_CRITIQUE_VERSION_${part}" "$got"
done

for part in Major Minor Patch; do
  want_var="major"
  [ "$part" = Minor ] && want_var="minor"
  [ "$part" = Patch ] && want_var="patch"
  want="${!want_var}"
  got="$(sed -n "s/^def version${part} : UInt32 := \([0-9]*\)$/\1/p" GraphosLeanCritique/Critique.lean)"
  if [ "$got" != "$want" ]; then err "Lean version${part} has '$got', want '$want'"; fi
  note "Lean version${part}" "$got"
done

abi_header="$(sed -n 's/^#define GRAPHOS_LEAN_CRITIQUE_ABI_VERSION \([0-9]*\)/\1/p' include/graphos_lean_critique.h)"
abi_lean="$(sed -n 's/^def abiVersion : UInt32 := \([0-9]*\)$/\1/p' GraphosLeanCritique/Critique.lean)"
if [ "$abi_header" != "$abi_lean" ]; then
  err "ABI version differs: header='$abi_header' Lean='$abi_lean'"
fi
note "ABI version (header = Lean)" "$abi_header"

# The exported version functions are literals (Lean lifts closed UInt32 defs to
# globals initialised at runtime, which a pure C caller never runs), so the
# literals must be checked explicitly against the canonical values.
abi_export="$(sed -n 's/^def abiVersionImpl (_unit : UInt8) : UInt32 := \([0-9]*\)$/\1/p' GraphosLeanCritique/Critique.lean)"
if [ "$abi_export" != "$abi_header" ]; then
  err "abiVersionImpl literal has '$abi_export', want '$abi_header'"
fi
note "Lean abiVersionImpl literal" "$abi_export"

packed=$(( major * 10000 + minor * 100 + patch ))
semver_export="$(sed -n 's/^def semverImpl (_unit : UInt8) : UInt32 := \([0-9]*\)$/\1/p' GraphosLeanCritique/Critique.lean)"
if [ "$semver_export" != "$packed" ]; then
  err "semverImpl literal has '$semver_export', want '$packed'"
fi
note "Lean semverImpl literal (packed SemVer)" "$semver_export"

# The packed semver must appear in the docs table if present.
if [ -f docs/abi.md ]; then
  if ! grep -q "packed SemVer.*$packed\|| \`$packed\` | packed SemVer" docs/abi.md; then
    echo "note: docs/abi.md does not mention packed SemVer $packed" >&2
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo "version sync check FAILED" >&2
  exit 1
fi
echo "version sync check passed (semver $version, ABI $abi_header)"
