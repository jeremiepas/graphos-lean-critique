#ifndef GRAPHOS_LEAN_CRITIQUE_H
#define GRAPHOS_LEAN_CRITIQUE_H

#include <stdint.h>

#define GRAPHOS_LEAN_CRITIQUE_ABI_VERSION 0
#define GRAPHOS_LEAN_CRITIQUE_VERSION "0.1.0 (graphos-lean-critique bootstrap)"

/* Error codes (v0 defines no fallible entry points beyond normalisation). */
#define GRAPHOS_LEAN_OK 0
#define GRAPHOS_LEAN_ERR_INVALID_ARGUMENT 1
#define GRAPHOS_LEAN_ERR_VERSION_MISMATCH 2
#define GRAPHOS_LEAN_ERR_OUT_OF_MEMORY 3

/* Reserved reason-mask bits (future, non-breaking addition). */
#define GRAPHOS_LEAN_REASON_CROSSES_FILE_TYPES   (1u << 0)
#define GRAPHOS_LEAN_REASON_SEPARATE_COMMUNITIES (1u << 1)
#define GRAPHOS_LEAN_REASON_INFERRED_CONNECTION  (1u << 2)

uint32_t graphos_lean_critique_abi_version(void);

uint64_t graphos_surprise_score(uint8_t confX10,
                               uint8_t crossFiletype,
                               uint8_t crossComm,
                               uint8_t inferred);

#endif /* GRAPHOS_LEAN_CRITIQUE_H */
