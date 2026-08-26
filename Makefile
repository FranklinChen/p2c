# Makefile for "p2c", the Pascal to C translator.
#  Copyright (C) 1989, 1993 David Gillespie.
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



# This file compiles and installs p2c in the "home" subdirectory of this
# directory, then runs it on various example programs in the "examples"
# subdirectory.  To install a permanent, public copy of p2c, see "README"
# and src/Makefile.

test:
	@echo "Compiling p2c, installing in `pwd`/home..."
	cd src; make install
	@echo ""
	@echo "Translating and compiling example files..."
	cd examples; make comp
	@echo ""
	@echo "Running the factorial example..."
	examples/fact
	@echo ""
	@echo "Running the 'e' computation example..."
	examples/e
	@echo ""
	@echo "Running the self-printing Pascal example..."
	examples/self >examples/self.out
	cat examples/self.out
	diff examples/self.p examples/self.out
	@echo ""
	@echo "Also try 'cref' and 'basic' in the examples directory."


install:
	cd src; make install


# Where "make install" puts the runtime. Must match HOMEDIR and LIBDIR in
# src/Makefile; change both together if you switch to the public install
# layout described there.
P2CHOME = home

# "make test" builds generated code in the compiler's default dialect, which
# still tolerates K&R definitions. This additionally checks that the generated
# C is valid strict ISO C23. Kept as its own target so it can be re-run during
# iteration without repeating the full build, and so a failing "test" does not
# hide the C23 status.
c23-check:
	./scripts/check-c23-output.sh $(CC) $(P2CHOME)

# Everything CI runs, in one command, so a local run predicts CI rather than
# approximating it. Note "test" is the historical entry point here and "check"
# is the superset, which is the reverse of the usual GNU convention.
check: test c23-check

.PHONY: test install check c23-check

