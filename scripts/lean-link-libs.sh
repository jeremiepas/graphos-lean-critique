#!/usr/bin/env bash
# lean-link-libs.sh — print GHC-compatible link flags for the Lean runtime.
#
# The Lean distribution decides the runtime link line: elan's official builds
# are compiled against libc++ (-lc++), while Nix's lean4 links libstdc++. Ask
# `leanc --print-ldflags` instead of hardcoding a list, and normalise the output
# for GHC:
#   - `-I <dir>` is dropped (not a link input)
#   - `-L <dir>` becomes `-L<dir>` (GHC does not accept the split form)
#   - absolute paths to gmp/libuv shared objects become -lgmp/-luv so the flags
#     stay redistributable (the build machine's store paths are not portable)
set -euo pipefail

leanc="${LEANC:-leanc}"

flags="$("$leanc" --print-ldflags)"

# shellcheck disable=SC2086
set -- $flags

out=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -I)
      shift 2
      ;;
    -I*)
      shift
      ;;
    -L)
      out+=("-L$2")
      shift 2
      ;;
    -L*)
      out+=("$1")
      shift
      ;;
    -f*)
      # Compiler-only flags that leanc also prints in --print-ldflags.
      shift
      ;;
    /*)
      base="$(basename "$1")"
      case "$base" in
        libgmp.so*) out+=("-lgmp") ;;
        libuv.so*) out+=("-luv") ;;
        *) out+=("$1") ;;
      esac
      shift
      ;;
    *)
      out+=("$1")
      shift
      ;;
  esac
done

printf '%s\n' "${out[*]}"
