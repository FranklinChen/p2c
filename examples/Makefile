
# Examples for "p2c", the Pascal to C translator.


# The following definitions assume p2c has been compiled into the "home"
# directory as shown in src/Makefile.
P2C = ../p2c
INC = ../home
LIB = ../home/libp2c.a


default: comp


# Translating everything:

trans:  fact.c  e.c  self.c  cref.c  basic.c

# One portable suffix rule instead of five copies. p2crc and the translator
# itself are inputs to every translation, so both are prerequisites: without
# them, editing p2crc or rebuilding p2c leaves stale .c files behind.
.SUFFIXES: .p .c

.p.c:
	$(P2C) $<

fact.c e.c self.c cref.c basic.c: p2crc $(P2C)



# Compiling everything:

# These rules compile p2c's *generated* output, which by default is K&R C, so
# they must name a dialect that still accepts it rather than trusting a
# compiler default that is drifting. Same reasoning as src/Makefile; the full
# story is in "Modern compiler compatibility" in README.md. Kept out of CFLAGS
# so an override cannot drop it.
STD = -std=gnu17

# CFLAGS is deliberately not assigned here, so that an inherited environment
# CFLAGS reaches these rules too. Do not put -Wno-* flags in it; fix the cause.

comp:  fact  e  self  cref  basic

fact: fact.c
	$(CC) $(STD) $(CFLAGS) -I$(INC) fact.c $(LIB) -o fact

e: e.c
	$(CC) $(STD) $(CFLAGS) -I$(INC) e.c $(LIB) -o e

self: self.c
	$(CC) $(STD) $(CFLAGS) -I$(INC) self.c $(LIB) -o self

cref: cref.c
	$(CC) $(STD) $(CFLAGS) -I$(INC) cref.c $(LIB) -o cref

basic: basic.c
	$(CC) $(STD) $(CFLAGS) -I$(INC) basic.c $(LIB) -lm -o basic






