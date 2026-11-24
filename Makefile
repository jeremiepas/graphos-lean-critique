# graphos-lean-critique — build the versioned C ABI library from Lean 4.
#
#   make            static library  (libgraphoslean.a)
#   make shared     shared library  (libgraphoslean.so)
#   make pkgconfig  graphos-lean-critique.pc
#   make test       C ABI smoke test against the static library
#   make bundle     release tarball contents under dist/
#   make install    install header + library + .pc under DESTDIR/PREFIX
#
# Toolchain discovery, in order:
#   1. `make LEAN_PREFIX=/path/to/lean4`
#   2. `lean`/`leanc` on PATH (elan or a system install)
#   3. a Nix store `*-lean4-$(LEAN_VERSION)` path

LEAN_VERSION ?= 4.29.1
VERSION := $(shell cat VERSION)
ABI_VERSION ?= 0

CC ?= cc
AR ?= ar
PREFIX ?= /usr/local
DESTDIR ?=
PKG_CONFIG ?= pkg-config

ifeq ($(origin LEAN_PREFIX), undefined)
  ifneq ($(shell command -v lean 2>/dev/null),)
    LEAN  := $(shell command -v lean)
    LEANC := $(shell command -v leanc)
  else
    LEAN_PREFIX := $(firstword $(wildcard /nix/store/*-lean4-$(LEAN_VERSION)))
    LEAN  := $(LEAN_PREFIX)/bin/lean
    LEANC := $(LEAN_PREFIX)/bin/leanc
  endif
else
  LEAN  := $(LEAN_PREFIX)/bin/lean
  LEANC := $(LEAN_PREFIX)/bin/leanc
endif

ifneq ($(wildcard $(LEANC)),)
  # Ask the toolchain itself: elan installs `lean` as a shim, so resolving the
  # binary's realpath does not lead to the toolchain's lib/lean directory.
  LEAN_LIBDIR := $(shell $(LEANC) --print-ldflags 2>/dev/null | awk '{for (i = 1; i <= NF; i++) { if ($$i == "-L") { print $$(i+1); exit } if ($$i ~ /^-L./) { sub(/^-L/, "", $$i); print $$i; exit } }}')
else
  LEAN_LIBDIR :=
endif

CCFLAGS  ?= -O2 -fPIC -Wall -Wextra -Werror
# GHC consumer (tests the ABI from the side that actually links it).
GHC ?= ghc
# Runtime link line comes from the toolchain itself: elan's Lean links libc++,
# Nix's links libstdc++. See scripts/lean-link-libs.sh.
LEAN_LINK_LIBS ?= $(shell LEANC="$(LEANC)" bash scripts/lean-link-libs.sh 2>/dev/null)
EXTRA_LIB_DIRS ?=
EXTRA_LDFLAGS ?=
# Same link line, spelled for GHC: GHC parses -Wl,... as a warning flag and
# rejects bare -pthread, so both have to go through the -optl prefix.
GHC_LEAN_LIBS := $(shell LEANC="$(LEANC)" bash scripts/lean-link-libs.sh 2>/dev/null | sed -e 's/-Wl,/-optl-Wl,/g' -e 's/ -pthread/ -optl-pthread/g')
PACKED_SEMVER := $(shell echo $(VERSION) | awk -F. '{print $$1*10000 + $$2*100 + $$3}')
LEAN_SRC := GraphosLeanCritique/Critique.lean
OBJS     := Critique.o abi_shim.o
DIST     := dist/graphos-lean-critique-$(VERSION)

all: libgraphoslean.a

# ── Lean → C ─────────────────────────────────────────────────────────────────
# Only the ABI module is extracted: theorems and checks are proof-only and must
# never reach the generated C surface.
Critique.c: $(LEAN_SRC)
	$(LEAN) -c $@ $<

Critique.o: Critique.c
	$(LEANC) -c $< -o $@

# The shim is the public ABI layer; compile it without Lean's hidden visibility
# so consumers can resolve the entry points even when linking a shared object.
abi_shim.o: src/abi_shim.c include/graphos_lean_critique.h
	$(CC) $(CCFLAGS) -Iinclude -c $< -o $@

# ── Libraries ────────────────────────────────────────────────────────────────
libgraphoslean.a: $(OBJS)
	$(AR) rcs $@ $^

libgraphoslean.so: $(OBJS)
	$(LEANC) -shared -o $@ $^

shared: libgraphoslean.so

# ── pkg-config ───────────────────────────────────────────────────────────────
graphos-lean-critique.pc: graphos-lean-critique.pc.in VERSION
	sed -e 's|@PREFIX@|$(PREFIX)|g' \
	    -e 's|@VERSION@|$(VERSION)|g' \
	    -e 's|@ABI_VERSION@|$(ABI_VERSION)|g' \
	    -e 's|@LEAN_LIBDIR@|$(LEAN_LIBDIR)|g' \
	    -e 's|@LIBS_PRIVATE@|$(LEAN_LINK_LIBS)|g' $< > $@

pkgconfig: graphos-lean-critique.pc

# ── Tests ────────────────────────────────────────────────────────────────────
# Compile the C test with the system compiler (Lean's `leanc` driver may point
# at a toolchain without the system C headers on some CI images) and link it
# with `leanc`, which supplies the Lean runtime link line.
abi_smoke: libgraphoslean.a tests/c/abi_smoke.c
	$(CC) $(CCFLAGS) -Iinclude -c tests/c/abi_smoke.c -o abi_smoke.o
	$(LEANC) abi_smoke.o libgraphoslean.a -o $@

test: abi_smoke
	./abi_smoke

# GHC links the archive at build time and calls it through foreign import
# ccall — the contract from the consumer side (the whole point of the bridge).
consumer: libgraphoslean.a tests/haskell/Consumer.hs
	$(GHC) -package-env - -O1 tests/haskell/Consumer.hs libgraphoslean.a \
	  $(addprefix -L,$(EXTRA_LIB_DIRS)) $(GHC_LEAN_LIBS) \
	  $(EXTRA_LDFLAGS) -o $@

test-haskell: consumer
	./consumer $(PACKED_SEMVER)

# Header must stay valid C99 and C++ (extern "C" guards, no C++-only syntax).
header-check:
	$(CC) -std=c99 -Wall -Wextra -Werror -pedantic -fsyntax-only -Iinclude tests/c/header_check.c
	c++ -std=c++17 -Wall -Wextra -Werror -fsyntax-only -Iinclude -x c++ tests/c/header_check.c

check: header-check test test-haskell
	bash scripts/check-version-sync.sh
	bash scripts/check-no-sorry.sh

# ── Release bundle ───────────────────────────────────────────────────────────
bundle: libgraphoslean.a libgraphoslean.so graphos-lean-critique.pc header-check
	rm -rf $(DIST)
	mkdir -p $(DIST)/include $(DIST)/lib/pkgconfig
	cp include/graphos_lean_critique.h $(DIST)/include/
	cp libgraphoslean.a libgraphoslean.so $(DIST)/lib/
	cp graphos-lean-critique.pc $(DIST)/lib/pkgconfig/
	cp VERSION LICENSE README.md CHANGELOG.md $(DIST)/
	cp -r docs $(DIST)/
	tar -czf dist/graphos-lean-critique-$(VERSION)-linux-$(shell uname -m).tar.gz -C dist graphos-lean-critique-$(VERSION)
	@echo "bundle: dist/graphos-lean-critique-$(VERSION)-linux-$(shell uname -m).tar.gz"

# ── Install ──────────────────────────────────────────────────────────────────
install: libgraphoslean.a graphos-lean-critique.pc
	install -d $(DESTDIR)$(PREFIX)/include $(DESTDIR)$(PREFIX)/lib/pkgconfig
	install -m 644 include/graphos_lean_critique.h $(DESTDIR)$(PREFIX)/include/
	install -m 644 libgraphoslean.a $(DESTDIR)$(PREFIX)/lib/
	install -m 644 graphos-lean-critique.pc $(DESTDIR)$(PREFIX)/lib/pkgconfig/

clean:
	rm -f Critique.c Critique.o abi_shim.o libgraphoslean.a libgraphoslean.so \
	      graphos-lean-critique.pc abi_smoke abi_smoke.o consumer consumer.hi consumer.o
	rm -rf dist

.PHONY: all shared pkgconfig test test-haskell header-check check bundle install clean
