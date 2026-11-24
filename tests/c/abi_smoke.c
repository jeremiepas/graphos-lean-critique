/*
 * abi_smoke.c — link-time and run-time verification of the public C ABI.
 *
 * Built by `make test` against libgraphoslean.a. Exits non-zero on the first
 * failing assertion, so CI fails if the ABI surface, the pinned fixtures, or
 * the version constants drift. Fixtures mirror
 * GraphosLeanCritique/Checks.lean and the Graphos contract inventory (AVI-1677).
 */

#include <stdint.h>
#include <stdio.h>

#include "graphos_lean_critique.h"

static int failures = 0;

static void check_u64(const char *what, uint64_t got, uint64_t want) {
  if (got != want) {
    fprintf(stderr, "FAIL %s: got %llu, want %llu\n", what,
            (unsigned long long)got, (unsigned long long)want);
    failures++;
  } else {
    printf("ok   %s = %llu\n", what, (unsigned long long)got);
  }
}

static void check_u32(const char *what, uint32_t got, uint32_t want) {
  if (got != want) {
    fprintf(stderr, "FAIL %s: got %u, want %u\n", what, (unsigned)got,
            (unsigned)want);
    failures++;
  } else {
    printf("ok   %s = %u\n", what, (unsigned)got);
  }
}

int main(void) {
  /* Version surface: the linked library must agree with the header it was
     compiled against. Graphos performs the same comparison at startup. */
  check_u32("abi version (library)", graphos_lean_critique_abi_version(),
            GRAPHOS_LEAN_CRITIQUE_ABI_VERSION);
  check_u32("semver (library)", graphos_lean_critique_semver(),
            GRAPHOS_LEAN_CRITIQUE_SEMVER);

  /* Frozen ABI v0 fixtures. */
  check_u64("score(0,1,1,0)", graphos_surprise_score(0, 1, 1, 0), 6);
  check_u64("score(0,1,1,1)", graphos_surprise_score(0, 1, 1, 1), 10);
  check_u64("score(9,0,0,0)", graphos_surprise_score(9, 0, 0, 0), 1);

  /* Bucket boundaries. */
  check_u64("score(2,0,0,0)", graphos_surprise_score(2, 0, 0, 0), 3);
  check_u64("score(3,0,0,0)", graphos_surprise_score(3, 0, 0, 0), 2);
  check_u64("score(7,0,0,0)", graphos_surprise_score(7, 0, 0, 0), 2);
  check_u64("score(8,0,0,0)", graphos_surprise_score(8, 0, 0, 0), 1);

  /* Argument normalisation is part of the contract: confidence clamps to 10
     and flags other than 1 are false. */
  check_u64("score(255,0,0,0)", graphos_surprise_score(255, 0, 0, 0), 1);
  check_u64("score(0,7,7,9)", graphos_surprise_score(0, 7, 7, 9), 3);

  /* Totality: every flag value (0, 1 and a non-boolean) with every confidence
     byte yields a score inside the documented 0..10 range. */
  {
    static const uint8_t flags[] = {0, 1, 255};
    uint32_t conf;
    uint64_t max = 0;
    for (conf = 0; conf < 256; conf++) {
      for (size_t a = 0; a < sizeof flags; a++) {
        for (size_t b = 0; b < sizeof flags; b++) {
          for (size_t c = 0; c < sizeof flags; c++) {
            uint64_t s = graphos_surprise_score((uint8_t)conf, flags[a],
                                                flags[b], flags[c]);
            if (s > max) max = s;
          }
        }
      }
    }
    check_u64("max score over the whole input domain", max, 10);
  }

  if (failures != 0) {
    fprintf(stderr, "%d ABI assertion(s) failed\n", failures);
    return 1;
  }
  printf("ABI v0 smoke test passed\n");
  return 0;
}
