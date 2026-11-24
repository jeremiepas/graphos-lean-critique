/*
 * graphos_lean_critique.h — stable C ABI of the Graphos Lean 4 critique
 * library (https://github.com/jeremiepas/graphos-lean-critique).
 *
 * Linked into Graphos at build time; there is no runtime plugin loading.
 *
 * Contract status: ABI v0, frozen by the Graphos change AVI-1677
 * (openspec/changes/AVI-1677-lean4-critique-replacement/contract-inventory.md).
 * Additive changes bump MINOR, ABI-breaking changes bump MAJOR and
 * GRAPHOS_LEAN_CRITIQUE_ABI_VERSION.
 *
 * Threading: every entry point is a pure function of its arguments, allocation
 * free, reentrant, and does not require the Lean runtime to be initialised.
 */
#ifndef GRAPHOS_LEAN_CRITIQUE_H
#define GRAPHOS_LEAN_CRITIQUE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ── Version ─────────────────────────────────────────────────────────────── */

/* Monotonic C ABI version. Bumped only on ABI-breaking changes. */
#define GRAPHOS_LEAN_CRITIQUE_ABI_VERSION 0

/* Release version (SemVer). Must equal the contents of the VERSION file. */
#define GRAPHOS_LEAN_CRITIQUE_VERSION "0.2.1"
#define GRAPHOS_LEAN_CRITIQUE_VERSION_MAJOR 0
#define GRAPHOS_LEAN_CRITIQUE_VERSION_MINOR 2
#define GRAPHOS_LEAN_CRITIQUE_VERSION_PATCH 1

/* Packed SemVer: major * 10000 + minor * 100 + patch (0.1.0 -> 100). */
#define GRAPHOS_LEAN_CRITIQUE_SEMVER \
  (GRAPHOS_LEAN_CRITIQUE_VERSION_MAJOR * 10000 + \
   GRAPHOS_LEAN_CRITIQUE_VERSION_MINOR * 100 + \
   GRAPHOS_LEAN_CRITIQUE_VERSION_PATCH)

/* ── Error codes ─────────────────────────────────────────────────────────── */

/* v0 defines no fallible entry points beyond implicit argument normalisation. */
#define GRAPHOS_LEAN_OK 0
#define GRAPHOS_LEAN_ERR_INVALID_ARGUMENT 1
#define GRAPHOS_LEAN_ERR_VERSION_MISMATCH 2
#define GRAPHOS_LEAN_ERR_OUT_OF_MEMORY 3

/* Reserved reason-mask bits (future, non-breaking addition). */
#define GRAPHOS_LEAN_REASON_CROSSES_FILE_TYPES   (1u << 0)
#define GRAPHOS_LEAN_REASON_SEPARATE_COMMUNITIES (1u << 1)
#define GRAPHOS_LEAN_REASON_INFERRED_CONNECTION  (1u << 2)

/* ── Entry points ────────────────────────────────────────────────────────── */

/* ABI version implemented by the linked library. Consumers must compare it
   with GRAPHOS_LEAN_CRITIQUE_ABI_VERSION before using the score predicate. */
uint32_t graphos_lean_critique_abi_version(void);

/* Packed SemVer of the linked release; compare with
   GRAPHOS_LEAN_CRITIQUE_SEMVER to detect a stale build. */
uint32_t graphos_lean_critique_semver(void);

/* Surprise score of a graph edge: the numeric arm of the Haskell
   Graphos.Domain.Analysis.surpriseScore.

   confX10        confidence * 10, clamped to 0..10 and bucketed <3, <8
   crossFiletype  1 when the endpoints live in different file categories
   crossComm      1 when the endpoints live in different communities
   inferred       1 when edgeRelation == Inferred
   returns        confBonus + 2*crossFiletype + 1*crossComm + semBonus,
                  always non-negative (0..10 for normalised arguments)

   Non-0/1 flag values are normalised to 0, so the result is total for every
   uint8_t input. */
uint64_t graphos_surprise_score(uint8_t confX10,
                                uint8_t crossFiletype,
                                uint8_t crossComm,
                                uint8_t inferred);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* GRAPHOS_LEAN_CRITIQUE_H */
