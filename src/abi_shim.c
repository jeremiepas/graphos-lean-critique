/*
 * abi_shim.c — the stable C ABI layer of graphos-lean-critique.
 *
 * The public entry points declared in include/graphos_lean_critique.h are
 * plain C functions defined here rather than raw Lean `@[export]` symbols.
 * Reasons:
 *
 *   - Lean cannot export a true zero-argument C function: a nullary
 *     `@[export]` becomes a writable data symbol initialised by the Lean
 *     module initialiser, which is not callable from `foreign import ccall`.
 *     Every Lean export below therefore takes one scalar `uint8_t` argument.
 *   - Argument normalisation is part of the frozen ABI contract (AVI-1677),
 *     so it lives in one reviewed place instead of being duplicated in the
 *     Lean codegen path.
 *   - The public symbol set stays stable even if Lean's codegen naming
 *     changes in a future toolchain.
 *
 * No heap allocation happens here, nothing is owned by the library, and every
 * function is pure and reentrant.
 */

#include "graphos_lean_critique.h"

/* Lean-exported implementations (renamed to keep the public names reserved
   for the shim below). */
extern uint32_t graphos_lean_critique_abi_version_impl(uint8_t unit);
extern uint32_t graphos_lean_critique_semver_impl(uint8_t unit);
extern uint64_t graphos_surprise_score_impl(uint8_t conf_x10,
                                            uint8_t cross_filetype,
                                            uint8_t cross_comm,
                                            uint8_t inferred);

/* ABI v0 buckets confidence at x10 < 3 and x10 < 8; values above 10 are
   clamped so the documented 0..10 domain holds for every input. */
static uint8_t normalise_conf_x10(uint8_t conf_x10) {
  return conf_x10 > 10u ? (uint8_t)10u : conf_x10;
}

/* Flags are booleans in the ABI: only the exact value 1 is truthy. */
static uint8_t normalise_flag(uint8_t flag) {
  return flag == 1u ? (uint8_t)1u : (uint8_t)0u;
}

uint32_t graphos_lean_critique_abi_version(void) {
  return graphos_lean_critique_abi_version_impl(0);
}

uint32_t graphos_lean_critique_semver(void) {
  return graphos_lean_critique_semver_impl(0);
}

uint64_t graphos_surprise_score(uint8_t conf_x10,
                                uint8_t cross_filetype,
                                uint8_t cross_comm,
                                uint8_t inferred) {
  return graphos_surprise_score_impl(normalise_conf_x10(conf_x10),
                                     normalise_flag(cross_filetype),
                                     normalise_flag(cross_comm),
                                     normalise_flag(inferred));
}
