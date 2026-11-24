# Releasing

Releases are tag-driven and produced by CI. Never build a release by hand on a
dirty tree, and never retag a published version.

## 1. Prepare the version

1. Bump `VERSION` (single source of truth).
2. Mirror it in `lakefile.toml` (`version = "X.Y.Z"`), in
   `include/graphos_lean_critique.h` (`GRAPHOS_LEAN_CRITIQUE_VERSION` and the
   three component macros) and in `GraphosLeanCritique/Critique.lean`
   (`versionMajor/versionMinor/versionPatch`).
3. Bump `GRAPHOS_LEAN_CRITIQUE_ABI_VERSION` (and `abiVersion` in
   `Critique.lean`) only for ABI-breaking changes.
4. Add a `CHANGELOG.md` entry under the new version, stating the ABI impact.
5. Run the local gate:

```sh
lake build
make check        # header (C99 + C++17), ABI smoke test, version + surface checks
make bundle       # inspect dist/
```

## 2. Merge and tag

```sh
git checkout main && git pull
git tag -a vX.Y.Z -m "graphos-lean-critique vX.Y.Z"
git push origin vX.Y.Z
```

The tag must equal `v$(cat VERSION)`; the release workflow fails otherwise.

## 3. What CI publishes

`.github/workflows/release.yml` performs a clean `lake build`, `make bundle`,
and attaches to the GitHub release:

```
graphos-lean-critique-X.Y.Z-linux-<arch>.tar.gz
```

containing:

| path | content |
| --- | --- |
| `include/graphos_lean_critique.h` | public header |
| `lib/libgraphoslean.a` | static library linked by Graphos |
| `lib/libgraphoslean.so` | shared library (same symbols) |
| `lib/pkgconfig/graphos-lean-critique.pc` | pkg-config, Lean runtime in `Libs.private` |
| `VERSION`, `LICENSE`, `README.md`, `CHANGELOG.md`, `docs/` | metadata and contract |

Each release also gets generated notes listing ABI impact, so the downstream
Graphos pin (AVI-1677, task V.3) can be updated deliberately.

## 4. Consumer pin

Graphos pins one release per integration branch:

- `graphos-lean-critique` version and ABI version recorded in
  `contract-inventory.md`;
- `Extra-lib-dirs`/`Include-dirs` point at the extracted bundle (or the Nix
  package built from the same tag);
- parity tests run against the pinned library. Upgrading is a separate change
  with a parity run, never a silent bump.
