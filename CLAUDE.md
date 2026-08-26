# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

p2c is a Pascal-to-C translator written by Dave Gillespie (1989-1993), licensed under GPL. It translates Pascal source files into C code, supporting multiple Pascal dialects (HP, Turbo/UCSD, VAX, Oregon Software, MPW, Sun/Berkeley, TI, Apollo) and partial Modula-2. The generated code and runtime library (p2clib.c, p2c.h) are not GPL-restricted.

This repository is FranklinChen's fork combining v1.21alpha2 with Ubuntu/Debian patches and Tom Schneider's v2.01 changes.

## Build Commands

```bash
# Build p2c and run example programs (from repo root)
make test

# Build and install to home/ directory (from repo root)
make install

# Build just the translator (from src/)
cd src && make all

# Clean build artifacts (from src/)
cd src && make clean
```

The build produces:
- `p2c` binary (in repo root for private install)
- `libp2c.a` runtime library (in home/)
- `home/p2c/p2c.h` runtime header

To translate and compile a Pascal file:
```bash
./p2c myfile.p
cc -Ihome myfile.c home/libp2c.a -o myfile
```

Note the include path is `home`, not `home/p2c`: generated code contains
`#include <p2c/p2c.h>`, so the directory *containing* `p2c/` must be on the
include path. For output that compiles on a current toolchain, use `p2c -a`
with `MainType int` set in a `p2crc`.

## Architecture

The codebase is ~41K lines of C in `src/`. The translation pipeline is:

1. **Configuration** (`trans.c`): Entry point. Parses `sys.p2crc` / `loc.p2crc` config files, command-line args
2. **Lexical analysis** (`lex.c`): Tokenizes Pascal input
3. **Parsing** (`parse.c`, `decl.c`, `expr.c`): Builds AST from tokens
4. **Translation** (`expr.c`, `pexpr.c`, `funcs.c`): Traverses AST and emits C
5. **Output** (`out.c`): Formats C code with indentation and line breaking

### Key source files

| File | Role |
|------|------|
| `src/trans.h` | Central header: all public types, globals, macros. Included by every module |
| `src/trans.c` | Main entry point, config parser, debug/dump functions |
| `src/parse.c` | Statement parser |
| `src/decl.c` | Declaration parser, type system |
| `src/expr.c` | Expression parser and C code generation |
| `src/pexpr.c` | Pascal-specific expression handling |
| `src/funcs.c` | Function/procedure handling, runtime library declarations |
| `src/lex.c` | Lexical analyzer |
| `src/out.c` | C output writer |
| `src/comment.c` | Comment preservation |
| `src/dir.c` | Custom translation module dispatcher |
| `src/hpmods.c` | HP Pascal-specific modules |
| `src/citmods.c` | Turbo/other dialect modules |
| `src/makeproto.c` | Standalone utility that generates `p2c.proto` and `p2c.hdrs` |

### Key data structures (in trans.h)

- `Symbol`: Symbol table entries
- `Type`: Type system representation
- `Expr`: Expression tree nodes
- `Stmt`: Statement tree nodes
- `Meaning`: Symbol meanings (functions, variables, types)

### Configuration system

- `src/sys.p2crc` (~83KB): System defaults: dialect settings, type mappings, function macros
- `src/loc.p2crc`: Local overrides (e.g., `Language Turbo` to change default dialect)

### Runtime library

- `src/p2clib.c`: Runtime support for translated programs (I/O, strings, sets, math, exceptions)
- `src/p2c.h`: Header for generated code (type definitions, compatibility macros, exception handling)

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every push/PR to main:

- **native**: `ubuntu-latest` and `macos-latest`, on their default toolchains.
- **modern-gcc**: the `gcc:15` and `gcc:16` container images. These exist
  because GCC 15 was the first release to default to C23, and neither
  `ubuntu-latest` nor `macos-latest` does. Both stayed green for months while
  p2c did not build on GCC 15 or 16 at all.
- **shellcheck**: lints the scripts at default severity.

The two build jobs run `make check`, which is `make test` plus
`scripts/check-c23-output.sh`. The script verifies p2c's *generated* C is valid
strict ISO C23, links, and produces correct output, over all five examples.
That is a separate question from whether p2c itself compiles, and `make test`
alone cannot answer it; see "Modern compiler compatibility" in `README.md`.

Run `make check` locally before pushing. It is the same command CI runs, so it
predicts CI rather than approximating it. Use `make c23-check` alone to re-run
just the gate.

## Modern Compiler Notes

There are **no warning-suppression flags in this tree**. `src/Makefile` sets
`STD = -std=gnu17` and `DEFS = -DTEST_MALLOC`, nothing more. Do not add `-Wno-*`
flags; if something warns, fix the cause.

`$(STD)` is passed separately in each compile rule and is deliberately **not**
part of `CFLAGS`, because distribution builds override `CFLAGS` on the command
line and would otherwise drop the dialect selection silently. Emptying `STD` makes
the build fail outright on GCC 15+, so treat it as a correctness precondition
rather than a preference.

Why a dialect flag rather than suppression, and what would actually fix the
underlying design, is explained in "Modern compiler compatibility" in
`README.md`. The code-level warning lives where it matters, on the `handler`
field in `src/trans.h`: read that comment before touching it.

Generated output is a separate matter, and two of its defaults produce code no
current Linux toolchain accepts:

- a bare `main(argc, argv)`, invalid since C99. Fixed by `MainType int`.
- `gets()`, removed in C11 and undeclared by glibc. Fixed by `UseGets 0`.

`examples/p2crc` sets both, and `p2c -a` adds prototypes. The global defaults in
`src/sys.p2crc` are deliberately left alone so existing downstreams see no change
in output; only their comments were corrected.

Beware that neither defect reproduces on macOS: clang still declares `gets`, and
`sbrk` arrives through another header there. Test on Linux, or in the `gcc:15`
container, before believing a compiler claim.

## Branches

Upstream releases are preserved pristine, so upstream changes can be diffed
directly:

- `upstream`, one unmodified commit per release, tagged `upstream/1.21alpha2`,
  `upstream/2.00`, `upstream/2.01`, `upstream/2.02`.
- `upstream-archives`, the original distribution archives bit-exact with
  `SHA256SUMS`.

```bash
git diff upstream/2.01 upstream/2.02   # exactly what upstream changed
git diff upstream/2.02 main            # exactly what this fork adds
```

Note: upstream 2.01 shipped a `src/p2c.h` that does not compile (it declares
`Void VAXdate(s)` as a bare K&R definition header). Do not import it wholesale.

## Custom Translation Modules

New dialect support is added via `src/dir.c` dispatcher. The `CUSTSRCS`/`CUSTOBJS`/`CUSTDEFS` variables in `src/Makefile` control which custom modules are linked. Currently: `hpmods.c` and `citmods.c`.

## Prototype Generation

Function prototypes (`p2c.proto`, `p2c.hdrs`) are auto-generated by the `makeproto` utility. After modifying function signatures in source files, run `make proto` in `src/` to regenerate.
