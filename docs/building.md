# Building graphos-lean-critique

Two independent builds live in this repository:

1. **Lean build** — `lake build`: type-checks the predicates, all spec theorems
   in `GraphosLeanCritique/Theorems.lean`, and the `#guard` fixtures in
   `GraphosLeanCritique/Checks.lean`. No `sorry`, no warnings allowed in CI.
2. **C ABI build** — `make`: extracts `GraphosLeanCritique/Critique.lean` to C,
   adds `src/abi_shim.c`, and archives the result.

## Prerequisites

- Lean 4, pinned by `lean-toolchain` (`leanprover/lean4:v4.29.1`), installed via
  elan or a Nix package. `lake` must be available.
- A C compiler (`cc`), `ar`, and a C++ runtime (`libstdc++`) for the Lean
  runtime.
- `gmp` and `libuv` development libraries at link time.
- The C++ runtime the Lean release was built against: elan's Linux Lean is
  built with libc++ (deb: `libc++-dev libc++abi-dev`), Nix's lean4 with
  libstdc++ (`g++`). `scripts/lean-link-libs.sh` prints the exact line.

NixOS:

```sh
nix-shell -p lean4 gmp libuv gcc
# or use an existing store path:
make LEAN_PREFIX=/nix/store/<hash>-lean4-4.29.1
```

When `lean` and `leanc` are on `PATH`, the `Makefile` uses them; otherwise it
falls back to the first `/nix/store/*-lean4-$(LEAN_VERSION)` path. `make` prints
the resolved toolchain on failure.

## Targets

| target | output |
| --- | --- |
| `make` | `libgraphoslean.a` (static, what Graphos links) |
| `make shared` | `libgraphoslean.so` (same public symbols) |
| `make pkgconfig` | `graphos-lean-critique.pc` |
| `make test` | builds and runs `tests/c/abi_smoke.c` |
| `make test-haskell` | links the archive into a GHC consumer (`tests/haskell/Consumer.hs`) and runs the fixtures |
| `make header-check` | header compiles as C99 (`-pedantic`) and C++17 |
| `make check` | header-check + test + version sync + surface checks |
| `make bundle` | release tarball under `dist/` |
| `make install` | installs header, static library and `.pc` under `PREFIX` |

`make install DESTDIR=/tmp/pkg PREFIX=/usr` is suitable for a distro package or
a Nix derivation.

## What gets extracted

Only `GraphosLeanCritique/Critique.lean` is compiled to C (`lean -c`). It has no
imports, so proofs and fixtures never reach the generated code — the ABI surface
stays primitive and serialisable. `scripts/check-no-sorry.sh` enforces that
invariant, and that every `@[export]` is declared either by the shim or the
public header.

## Linking from Haskell (Cabal)

```cabal
  Include-dirs:     <prefix>/include
  Extra-libraries:  graphoslean lean Init Std leanrt libleancpp libleanrt
  Extra-lib-dirs:   <prefix>/lib
  extra-libraries:  stdc++ gmp uv m dl pthread
```

With pkg-config, `pkg-config --static --cflags --libs graphos-lean-critique`
yields the same flags (including the Lean runtime directory).

`make test-haskell` proves that path: it builds `libgraphoslean.a`, links it
into a plain GHC program and calls all three entry points through
`foreign import ccall`, asserting the ABI fixtures and the version surface. On
NixOS pass the gmp/libuv directories explicitly:

```sh
make test-haskell \
  EXTRA_LIB_DIRS="$(nix eval --raw nixpkgs#libuv)/lib $(nix eval --raw nixpkgs#gmp)/lib" \
  EXTRA_LDFLAGS="-optl-Wl,-rpath,$(nix eval --raw nixpkgs#libuv)/lib"
```

## Troubleshooting

- `undefined reference to lean_*` — the Lean runtime libraries are missing from
  the link line; use `pkg-config --static` or the `Libs.private` list above.
- `cannot execute graphos_lean_critique_abi_version` / crash on the version call
  — the consumer linked the pre-0.2.0 release, where the version symbol was a
  Lean data symbol rather than a function. Upgrade to 0.2.0 or later.
- Wrong store path in `LEAN_PREFIX` — `ls /nix/store/*-lean4-4.29.1/bin`.
