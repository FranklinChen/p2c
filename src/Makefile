# Makefile for "p2c", the Pascal to C translator.
#  Copyright (C) 1989, 1990, 1991, 1992, 1993 Free Software Foundation.
#  Author: Dave Gillespie.
#  Author's address: daveg@synaptics.com.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (any version).

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

SHELL = /bin/sh

# Directories (private version)
HOMEDIR = ../home
INCDIR = ../home/p2c
BINDIR = ..
LIBDIR = ../home
MANDIR = ../home
MANFILE = p2c.cat.inst     # human-readable manual (for cat.1), built below
#MANFILE = p2c.man.inst    # uncompressed nroff source (for man.1)
#MANFILE = p2c.man.Z       # compressed nroff source (for man.1.Z)

# Directories (public version)
#HOMEDIR = /usr/lib/p2c
#INCDIR = /usr/include/p2c
#BINDIR = /usr/bin
#LIBDIR = /usr/lib
#MANDIR = /usr/man/man1
#MANFILE = p2c.man.inst

# Compiler options
CC = cc                    # you may wish to use gcc here instead
OPT = # -O		   # uncomment this for optimization
DEB = # -g		   # uncomment this for debugging

# These sources are C17-era and break under C23. See the "handler" comment in
# trans.h for the mechanism, and "Modern compiler compatibility" in README.md.
# Needs GCC 8+ or Clang 6+; remove it if building with something older.
STD = -std=gnu17

DEFS =	-DTEST_MALLOC
CFLAGS = $(OPT) $(DEB) $(DEFS)
LFLAGS =

# $(STD) is deliberately NOT folded into CFLAGS. Distribution builds routinely
# override CFLAGS on the command line, e.g. "make CFLAGS='-O2 -g'", which would
# silently drop the dialect selection and fail to build on GCC 15 and later.
# The dialect is a correctness precondition, not a preference.
#
# Every compile goes through $(COMPILE) so that a rule which omits the dialect
# is a visible deviation rather than an easy oversight. CPPFLAGS and LDFLAGS
# are honoured because distribution builds inject hardening flags through them,
# and LINK passes CFLAGS too so that flags like -fsanitize reach the link.
COMPILE = $(CC) -c $(STD) $(CPPFLAGS) $(CFLAGS)
LINK = $(CC) $(CFLAGS) $(LFLAGS) $(LDFLAGS)

.c.o:
	$(COMPILE) -o $@ $<


# Custom translator modules
CUSTSRCS = hpmods.c citmods.c
CUSTOBJS = hpmods.o citmods.o
CUSTDEFS = -DCUST1=hpmods -DCUST2=citmods


# File names
P2CSRCS = trans.c stuff.c out.c comment.c lex.c parse.c decl.c \
          expr.c pexpr.c funcs.c dir.c
P2COBJS = trans.o stuff.o out.o comment.o lex.o parse.o decl.o \
          expr.o pexpr.o funcs.o dir.o

SRCS = $(P2CSRCS) $(CUSTSRCS)
OBJS = $(P2COBJS) $(CUSTOBJS)

LIBSRCS = p2clib.c loc.p2clib.c
LIBOBJS = p2clib.o loc.p2clib.o
OTHERLIBOBJS =

# Header dependencies. Without these, editing a header leaves stale objects
# in an incremental build; only dir.o and trans.o declared any before.
$(OBJS): trans.h p2c.hdrs p2c.proto
$(LIBOBJS): p2c.h

# Absolute install paths, compiled into p2c. Each creates its directory first:
# "cd DIR; pwd" on a missing DIR prints the current directory, which silently
# made src/ p2c's home in a fresh tree.
ABSHOMEDIR = `mkdir -p $(HOMEDIR) && cd $(HOMEDIR) && pwd`
ABSINCDIR = `mkdir -p $(INCDIR) && cd $(INCDIR) && pwd`
ABSLIBDIR = `mkdir -p $(LIBDIR) && cd $(LIBDIR) && pwd`

MISCSRCS = makeproto.c
PROTOS = p2c.proto p2c.hdrs
HDRS = trans.h p2c.h


# Top-level targets
all: proto p2c libp2c.a p2c.cat.inst
proto: $(PROTOS)


# Making p2c
p2c: $(OBJS)
	$(LINK) $(OBJS) -o p2c

dir.o: dir.c
	$(COMPILE) $(CUSTDEFS) dir.c

trans.o: trans.c
	$(COMPILE) -DHASDUMPS -DP2C_HOME=\"$(ABSHOMEDIR)\" trans.c


# Making and using makeproto
p2c.hdrs: $(SRCS) makeproto
	./makeproto -n -m -h -t16 -a35 -s0 -x $(SRCS) -o p2c.hdrs

p2c.proto: $(SRCS) makeproto
	./makeproto -n -m -h -t16 -a35 -s1 -i $(SRCS) -o p2c.proto

makeproto: makeproto.o
	$(LINK) makeproto.o -o makeproto


# Making the p2c runtime library
libp2c.a: $(LIBOBJS)
	ar r libp2c.a $(LIBOBJS) $(OTHERLIBOBJS)

p2clib.o: p2clib.c p2c.h


# Making the p2c man page
p2c.man.inst: p2c.man
	sed -e "s;--HOMEDIR--;$(ABSHOMEDIR);"   \
            -e "s;--INCDIR--;$(ABSINCDIR);"     \
            -e "s;--LIBDIR--;$(ABSLIBDIR);"     \
            p2c.man >p2c.man.inst

p2c.man.Z: p2c.man.inst
	compress -c p2c.man.inst >p2c.man.Z

# p2c.cat is the formatted manual as shipped upstream, checked in for systems
# without nroff. The build writes p2c.cat.inst instead of overwriting it, so a
# build never modifies a tracked file: formatting with nroff where available,
# otherwise falling back to the shipped copy.
p2c.cat.inst: p2c.man.inst
	if [ -f /usr/bin/nroff -o -f /bin/nroff ];  \
	    then nroff -man p2c.man.inst >p2c.cat.inst; \
	    else cp p2c.cat p2c.cat.inst; fi


# The p2cc script.
p2cc: p2cc.perl
	sed -e "s;--HOMEDIR--;$(ABSHOMEDIR);"   \
	    -e "s;--INCDIR--;$(ABSINCDIR);"     \
	    -e "s;--LIBDIR--;$(ABSLIBDIR);"     \
	    -e "s;/bin/perl;`which perl`;"      \
	    p2cc.perl >p2cc
	chmod a+x p2cc



# Initially installing p2c:
#  First, make sure $(HOMEDIR) and $(INCDIR) exist and are writable;
#  Second, make sure $(LIBDIR), $(BINDIR) and $(MANDIR) are writable;
#  Third, execute "make install" to compile and set things up.
# (You may need to have a system operator do these steps for you.)

COPY = cp

newhome:
	rm -f trans.o     # force trans.c to be recompiled (if HOMEDIR changes)

# Phased, because under "make -j" the copies below raced makedirs and failed
# with "No such file or directory". Each phase may itself run in parallel.
install:
	$(MAKE) makedirs
	$(MAKE) install-files

install-files: \
	$(BINDIR)/p2c         \
	$(BINDIR)/p2cc        \
	$(LIBDIR)/libp2c.a    \
	$(MANDIR)/p2c.1	      \
	$(INCDIR)/p2c.h	      \
	$(HOMEDIR)/p2crc      \
	$(HOMEDIR)/loc.p2crc  \
	$(HOMEDIR)/system.imp \
	$(HOMEDIR)/system.m2  \
	$(HOMEDIR)/turbo.imp  \
	$(HOMEDIR)/string.pas

SHELL=/bin/sh

# Phony because this directory holds a file named INSTALL, which on a
# case-insensitive filesystem (macOS) would otherwise satisfy "install" and
# make it silently do nothing.
.PHONY: install install-files makedirs proto all clean

makedirs:
	mkdir -p $(HOMEDIR) $(BINDIR) $(LIBDIR) $(MANDIR) $(INCDIR)

$(BINDIR)/p2c: p2c
	$(COPY)  p2c          $(BINDIR)/p2c

$(BINDIR)/p2cc: p2cc
	$(COPY)  p2cc         $(BINDIR)/p2cc

$(LIBDIR)/libp2c.a: libp2c.a
	$(COPY)  libp2c.a     $(LIBDIR)/libp2c.a
	if [ -f /usr/bin/ranlib -o -f /bin/ranlib ]; then ranlib $(LIBDIR)/libp2c.a; fi

$(MANDIR)/p2c.1: $(MANFILE)
	$(COPY)  $(MANFILE)   $(MANDIR)/p2c.1

$(INCDIR)/p2c.h: p2c.h
	$(COPY)  p2c.h        $(INCDIR)/p2c.h

$(HOMEDIR)/p2crc: sys.p2crc
	$(COPY)  sys.p2crc    $(HOMEDIR)/p2crc

$(HOMEDIR)/loc.p2crc: loc.p2crc
	$(COPY)  loc.p2crc    $(HOMEDIR)/loc.p2crc

$(HOMEDIR)/system.imp: system.imp
	$(COPY)  system.imp   $(HOMEDIR)/system.imp

$(HOMEDIR)/system.m2: system.m2
	$(COPY)  system.m2    $(HOMEDIR)/system.m2

$(HOMEDIR)/turbo.imp: turbo.imp
	$(COPY)  turbo.imp    $(HOMEDIR)/turbo.imp

$(HOMEDIR)/string.pas: string.pas
	$(COPY)  string.pas   $(HOMEDIR)/string.pas



# Miscellaneous
tags:
	etags $(SRCS) $(LIBSRCS) $(MISCSRCS) $(HDRS)

clean.o:
	rm -f $(OBJS)

# makeproto and p2cc were missing here, so "make clean" left stale binaries
# behind. That matters: makeproto generates the checked-in p2c.proto and
# p2c.hdrs, so a stale one silently keeps producing output from older sources.
#
# $(PROTOS) is removed even though those two files are checked in, because
# makeproto regenerates them byte-for-byte. p2c.cat is checked in too but is
# NOT removed, because regenerating it needs nroff, which the build treats as
# optional; the build never writes it, only p2c.cat.inst. The rule is "remove
# what we can reproduce", not "remove what is untracked".
clean:
	rm -f $(OBJS) $(LIBOBJS) $(PROTOS) p2c p2cc makeproto makeproto.o libp2c.a \
	      p2c.man.inst p2c.cat.inst

wc:
	wc $(SRCS) $(LIBSRCS) trans.h

test:
	echo '"make test" should be used in the outer-level p2c directory.'
	echo 'Type "cd .." and "make test" again.'

