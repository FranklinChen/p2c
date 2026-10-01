# p2c: Pascal to C Translator

[![Build and Test](https://github.com/FranklinChen/p2c/actions/workflows/ci.yml/badge.svg)](https://github.com/FranklinChen/p2c/actions/workflows/ci.yml)

> **Status: no longer maintained.** This repository was a hobby project over
> the years, out of nostalgia for programming in Pascal back in the day, and
> for having used p2c itself in the 1990s.
>
> In 2026 I did one final round of work to address problems that downstream
> users had brought to my attention: p2c now builds on current GCC and clang,
> the fixes that distributions and M-Tx had been carrying as private patches
> are in this repository, and every surviving upstream release is preserved on
> the `upstream` branches. That work is finished, and I am not maintaining p2c
> beyond it. If you would like to take the project over, you are welcome to
> fork it, or reach me through
> [my GitHub profile](https://github.com/FranklinChen).
>
> AI disclosure: most of the final work was done by Claude, with me doing my
> best to review what was done.

**p2c** translates Pascal source into C. It was written by Dave Gillespie
(1989-1993) and later maintained by Tom Schneider, whose last release was 2.02
in 2022. This repository is 2.02 plus the fixes described above, released as
**2.02.1**.

It accepts HP Pascal, Turbo/UCSD Pascal (including Turbo Pascal 6.0 objects),
DEC VAX Pascal, Oregon Software Pascal/2, Macintosh MPW Pascal (including
Object Pascal), Sun/Berkeley Pascal, Texas Instruments Pascal, Apollo Domain
Pascal, and some Modula-2.

## Which p2c do you want?

| If you want to... | Use |
|---|---|
| **Run** Pascal programs | [Free Pascal](https://www.freepascal.org/), an actively developed Pascal compiler. p2c is a translator, not a compiler. |
| **C source** translated from Pascal | This repository, with the recipe below. |
| Schneider's **original releases** | His site, [`https://alum.mit.edu/www/toms/p2c/`](https://alum.mit.edu/www/toms/p2c/), or the pristine copies on this repository's `upstream` branch. |

## Building

Needs `make` and a C compiler. `perl` is used for the `p2cc` wrapper script,
and `nroff`, if present, for the formatted manual.

```bash
make test       # build, install into ./home, translate and run the examples
make check      # make test, plus a strict C23 check of the generated C
```

This puts `p2c` in the repository root and its runtime library and header,
`libp2c.a` and `p2c/p2c.h`, under `home/`. To install elsewhere, set the
directory variables at the top of `src/Makefile` (`HOMEDIR`, `BINDIR`,
`LIBDIR`, `INCDIR`, `MANDIR`), either there or on the `make` command line.

## Translating a program

p2c's default output is K&R-era C that current compilers reject: `main` has
no return type, which has been invalid since C99, and string input uses
`gets()`, which C11 removed. Two settings and one flag fix that. Put a file
named `p2crc` in the directory you run p2c from:

```
MainType	int
UseGets	0
```

Then translate with `-a`, which emits ANSI prototypes, and compile:

```bash
./p2c -a myfile.p
cc -Ihome myfile.c home/libp2c.a -lm -o myfile
```

The include path is `home`, not `home/p2c`, because generated code says
`#include <p2c/p2c.h>`.

For a self-contained program, this produces C that compiles as strict ISO C23
(`-std=c23 -pedantic-errors`), and CI checks that on every push. A program that
calls routines from outside its own source (screen handling, operating-system
modules and the like) also needs `FuncMacro` lines in `p2crc` mapping those
calls onto C; `examples/p2crc` shows both, and is what `examples/basic.p` needs.

The defaults themselves are unchanged, so that existing users' output does not
change underneath them.

## Modern compiler compatibility

CI builds p2c, translates the examples, and compiles and runs the result on
GCC 15 and 16 and on the default compilers of GitHub's Ubuntu and macOS
runners (GCC 13 and Apple clang 21 at this release). It also checks the
generated C under the draft-C23 modes of GCC 12 and clang 16.

`src/Makefile` compiles p2c itself with `-std=gnu17`. That is not warning
suppression: p2c's sources rely on `f()` meaning "parameters unspecified",
which C23 redefines to mean `f(void)`, so they genuinely are pre-C23 code.
Without it, GCC 16, which like GCC 15 defaults to C23, reports 169 errors.
The cause, and what a real repair would involve, is described in the comment
on the `handler` field in `src/trans.h`.

## Known issues

These are recorded rather than fixed, for whoever picks this up:

- **The `handler` field in `src/trans.h`** holds five differently shaped
  function pointers in one untyped slot, which is why `-std=gnu17` is needed.
  The comment there, and `scripts/handler-census.sh`, give the scope of a
  proper fix.
- **Two reads of uninitialized variables**: `curtokmeaning = mp` in
  `parse_constructor` (`src/funcs.c`, around line 1625), and `ex->val.type`
  read before `ex` is set on the non-bracket `delete` path in `src/pexpr.c`
  (around line 2216). Both are on rarely used paths and predate this fork.
- **Warnings under clang**: building p2c and its runtime with Apple clang 21
  gives 769, of which 748 are `-Wdeprecated-non-prototype` for the K&R function
  definitions throughout and 21 are `-Wdangling-else`.
- **Pascal identifiers that C23 reserves**, such as `bool` or `nullptr`, are
  not renamed by default, so a program using one will not compile as C23.
  An `AvoidName` line in `p2crc` renames it.
- **No `DESTDIR` support** in `make install`.
- `src/p2c.cat`, the preformatted manual used when `nroff` is missing, is the
  copy upstream shipped and describes 1.21alpha.
- `examples/c/` holds Gillespie's original reference translations. They no
  longer match current output, because `examples/p2crc` changes `main` and
  string input.

## Repository layout

| Branch or tag | Contents |
|---|---|
| `main` | p2c 2.02.1: upstream, the Debian patches, and the 2026 fixes. |
| tag `2.02.1` | The final release from this repository. |
| `upstream` | Each upstream release unmodified, one commit each, tagged `upstream/1.21alpha2`, `upstream/2.00`, `upstream/2.01` and `upstream/2.02`. |
| `upstream-archives` | The original distribution archives, byte for byte, with `SHA256SUMS`. |
| `ubuntu` | The Ubuntu 1.21alpha2-3 packaging, including its Debian patch series. |
| tags `1.21`, `1.21alpha2`, `1.21alpha2-3` | Older snapshots of `main`, kept because others build from them. `1.21` contains Schneider's 2.01 changes despite its name. |

Because the upstream releases are kept pristine, these work:

```bash
git diff upstream/2.01 upstream/2.02   # exactly what Schneider changed in 2.02
git diff upstream/2.02 main            # exactly what this repository adds
```

The archives are committed because the surviving releases are served from a
single host, and every earlier p2c distribution site has gone dark. The
scripts that maintain and verify these branches are described in
[`scripts/README.md`](scripts/README.md).

## License

p2c is distributed under the GNU General Public License: the source files say
"any version", and [`COPYING`](COPYING) carries version 2. The runtime library
(`src/p2clib.c`, `src/p2c.h`) and the C code p2c generates are not restricted
by it; the runtime's own headers say it "may be copied, modified, etc. in any
way".

Gillespie's original installation notes are in [`README`](README), and
historical; the build instructions above supersede them.
