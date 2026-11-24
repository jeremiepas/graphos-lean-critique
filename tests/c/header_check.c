/* Compile-only check: the public header must be valid C99 and C++17, and every
   declared macro must expand. Built by `make header-check`. */

#include <stdint.h>

#include "graphos_lean_critique.h"

#if GRAPHOS_LEAN_CRITIQUE_ABI_VERSION < 0
#error "abi version macro must be non-negative"
#endif

#if GRAPHOS_LEAN_CRITIQUE_SEMVER != (GRAPHOS_LEAN_CRITIQUE_VERSION_MAJOR * 10000 + \
                                     GRAPHOS_LEAN_CRITIQUE_VERSION_MINOR * 100 + \
                                     GRAPHOS_LEAN_CRITIQUE_VERSION_PATCH)
#error "semver packing is inconsistent"
#endif

static uint32_t (*abi_version_fn)(void) = graphos_lean_critique_abi_version;
static uint32_t (*semver_fn)(void) = graphos_lean_critique_semver;
static uint64_t (*score_fn)(uint8_t, uint8_t, uint8_t, uint8_t) =
    graphos_surprise_score;

int header_check_reachable(void) {
  return abi_version_fn != 0 && semver_fn != 0 && score_fn != 0 &&
         GRAPHOS_LEAN_OK == 0 && GRAPHOS_LEAN_ERR_VERSION_MISMATCH == 2;
}
