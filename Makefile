LEAN_PREFIX ?= /nix/store/cwilxazl2n8f59lksc4xihx560485ci8-lean4-4.29.1
LEAN  := $(LEAN_PREFIX)/bin/lean
LEANC := $(LEAN_PREFIX)/bin/leanc

all: libgraphoslean.a

Critique.c: GraphosLeanCritique/Critique.lean
	$(LEAN) -c $@ $<

Critique.o: Critique.c
	$(LEANC) -c $< -o $@

libgraphoslean.a: Critique.o
	ar rcs $@ $<

clean:
	rm -f Critique.c Critique.o libgraphoslean.a

.PHONY: all clean
