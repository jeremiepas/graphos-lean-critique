# Security policy

## Reporting

Please **do not** open a public issue for a vulnerability. Use GitHub's private
vulnerability reporting ("Report a vulnerability" under the Security tab) or
email the maintainer listed on the repository profile. Include the release tag,
the ABI version (`graphos_lean_critique_abi_version()`), and a minimal
reproducer.

You can expect an acknowledgement within 7 days and a public advisory once a
fix is released.

## Scope

This library is a pure, allocation-free C ABI over Lean 4 predicates. The
relevant classes of issue are:

- memory-safety or undefined behaviour in the C ABI layer (`src/abi_shim.c`) or
  the generated code;
- out-of-bounds or unsound extraction (`@[export]` surface leaking proof state);
- build-time supply-chain issues: the pinned Lean toolchain, CI actions, release
  artifacts.

## Supported versions

Only the latest release line receives fixes; ABI v0 (0.1.x) is supported.
