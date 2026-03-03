# p2c: Pascal to C Translator

[![Build and Test](https://github.com/FranklinChen/p2c/actions/workflows/ci.yml/badge.svg)](https://github.com/FranklinChen/p2c/actions/workflows/ci.yml)

**p2c** is a Pascal-to-C translator originally written by Dave Gillespie
(1989-1993), copyright Free Software Foundation, distributed under the GPL.
The generated C code and runtime library (`p2clib.c`, `p2c.h`) are **not**
GPL-restricted.

p2c supports a wide range of Pascal dialects:

- HP Pascal
- Turbo/UCSD Pascal (including Turbo Pascal 6.0 OOP)
- DEC VAX Pascal
- Oregon Software Pascal/2
- Macintosh Programmer's Workshop Pascal (including Object Pascal)
- Sun/Berkeley Pascal
- Texas Instruments Pascal
- Apollo Domain Pascal
- Partial Modula-2 support

See the original [`README`](README) for Gillespie's installation instructions.

---

## Building

Requires only `make`, a C compiler (`cc`/`gcc`/`clang`), `nroff`, and `perl`.

```bash
# Build p2c and run example programs
make test

# Build and install to home/ directory
make install

# Build just the translator
cd src && make all

# Clean build artifacts
cd src && make clean
```

The build produces:
- `p2c` binary (in repo root for private install)
- `libp2c.a` runtime library (in `home/`)
- `home/p2c/p2c.h` runtime header

To translate and compile a Pascal file:
```bash
./p2c myfile.p
cc -Ihome/p2c myfile.c home/libp2c.a -o myfile
```

### Modern compiler compatibility

The codebase uses K&R C idioms. The Makefile passes
`-Wno-implicit-function-declaration -Wno-implicit-int` to suppress
warnings-as-errors that modern compilers (GCC 14+, Clang 16+) now enable by
default. A forward declaration in `p2clib.c` and a missing `<stdlib.h>` in
`makeproto.c` have been fixed directly.

For GCC 15+ (which defaults to C23), you may also need:

```
-Wno-error=incompatible-pointer-types
-std=gnu17
```

---

## History

### Original development (1989-1993)

p2c was written by **Dave Gillespie** (c/o Synaptics, Inc.) and was listed as a
[GNU project](https://www.gnu.org/software/p2c/) (that URL now redirects to a
2006 Wayback Machine snapshot). The original distribution site was
`csvax.cs.caltech.edu` (long dead). The HISTORY file in the source tracks 22
versions from 1.00 to 1.21alpha. The final Gillespie release was
**v1.21alpha-07.Dec.93**.

### The Schneider continuation

**Tom Schneider**, a researcher at NIH/NCI Frederick, maintained p2c beyond
Gillespie's final release. His changes were practical fixes for modern compiler
compatibility:

- Renamed symbols that clash with modern libc/macOS headers (`logf` ->
  `logfile`, `getline` -> `getaline`)
- General build fixes for newer GCC versions

Schneider published versions **1.22**, **2.01**, and **2.02**. His distribution
sites (`schneider.ncifcrf.gov`, `users.fred.net/tds/lab/p2c/`,
`alum.mit.edu/www/toms/p2c/`) are all currently unreachable (as of March 2026).

### This fork

This repository ([FranklinChen/p2c](https://github.com/FranklinChen/p2c)) is
the most complete GitHub source for p2c. It was assembled from:

1. **Gillespie's v1.21alpha2** base
2. **Ubuntu/Debian patches** from `p2c_1.21alpha2-3.diff.gz` (fixing Debian
   bugs #305412, #552828, the built-in `logf` conflict, and a manpage issue)
3. **Schneider's v2.01 changes** merged via PR #1 (touching `comment.c`,
   `decl.c`, `lex.c`, `out.c`, `parse.c`, `trans.c`, `trans.h`, and the man
   page — mostly the `logf`/`getline` renames)
4. **Modern compiler fixes** (forward declaration in `p2clib.c`, missing
   `<stdlib.h>` in `makeproto.c`, `-Wno-*` flags in the Makefile)

**Gap:** Does not contain Schneider's v2.02 changes (the download is currently
unavailable).

### Version timeline

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.00 | ~1989 | Gillespie | Initial release |
| ... | 1989-1993 | Gillespie | 22 releases adding dialect support |
| 1.20 | ~1992 | Gillespie | Last "stable" release |
| 1.21alpha2 | 1993-12-07 | Gillespie | Final Gillespie release |
| 1.22 | unknown | Schneider | Minor fixes |
| 2.01 | unknown | Schneider | `logf`/`getline` renames for modern compilers |
| 2.02 | ~2022 | Schneider | Latest known release (download unavailable) |

---

## GitHub Landscape

### Direct p2c repositories

| Repository | Stars | Base version | Last commit | Notes |
|------------|-------|-------------|-------------|-------|
| [FranklinChen/p2c](https://github.com/FranklinChen/p2c) | 39 | v1.21alpha2 + v2.01 | 2017 | **This repo.** Most complete source. |
| [Classic-Tools/p2c](https://github.com/Classic-Tools/p2c) | 4 | Gillespie only | 2015 | Historical archive: each release as a commit. |
| [djipi/p2c](https://github.com/djipi/p2c) | 13 | v1.21alpha2 | 2020 | Claims Win32 support. |

### Notable forks of this repo

| Fork | Last pushed | Changes |
|------|------------|---------|
| [reneeverly/p2c](https://github.com/reneeverly/p2c) | 2023-01-29 | macOS build fix + README update |
| All others | 2017 | Unmodified |

### Related projects (not derived from p2c)

| Project | URL | Notes |
|---------|-----|-------|
| ptoc | [knizhnik/ptoc](https://github.com/knizhnik/ptoc) | Independent Pascal-to-C++ converter (34 stars) |
| pas2cpp | [parstools/pas2cpp](https://github.com/parstools/pas2cpp) | Attempted OOP extension of p2c (unrealized) |
| Free Pascal | [Homebrew formula](https://formulae.brew.sh/formula/fpc) | Full Pascal compiler (not a translator) |

---

## Linux Distribution Packaging

| Distribution | Version | Status |
|---|---|---|
| **AUR (Arch Linux)** | 2.02 | Active (2025). Notes GCC 15 issues. |
| **GNU Guix** | 2.02 | Active. Uses `-Wno-implicit-function-declaration`. |
| **Slackware current** | 2.02 | Development branch. |
| **Slackware 15.0** | 2.01 | Stable release. |
| **Mageia Cauldron** | 2.02 | Development. |
| **Mageia 9** | 1.22 | Stable. |
| **PLD Linux** | 1.22 | RPM spec; last commit 2025-07-14. |
| **pkgsrc (NetBSD)** | 1.20nb1 | Still points at dead Caltech FTP. |
| **FreeBSD ports** | 2.01 (was) | **Deleted** 2019 ("BROKEN: unfetchable"). |
| **Debian** | -- | Removed ~2010. Open RFP [#895637](https://bugs.debian.org/895637) since 2018. |
| **Homebrew** | -- | Not packaged. |

Distributions packaging v2.02 all point to `users.fred.net`, which is currently
unreachable.

---

## Real-World Usage

Despite its age, p2c has a specific, active use case:

- **[M-Tx](https://ctan.org/pkg/m-tx)** (Music from TeXt): a preprocessor for
  MusiXTeX, written in Pascal by Dirk Laurie. M-Tx's build process uses p2c to
  translate Pascal source to C, which is then compiled and included in TeXLive
  distributions. Bob Tennent's Debian RFP (#895637) specifically cites this
  dependency.

---

## Known Source URLs

| URL | Status | Version |
|-----|--------|---------|
| `ftp://csvax.cs.caltech.edu/pub/p2c-1.20.tar.Z` | Dead (1990s) | 1.20 |
| `https://schneider.ncifcrf.gov/p2c/` | Dead | 2.01 |
| `http://users.fred.net/tds/lab/p2c/` | Unreachable | 2.02 |
| `https://alum.mit.edu/www/toms/p2c/` | Unknown | -- |
| `https://github.com/FranklinChen/p2c` | **Live** | 2.01 |
| `https://github.com/Classic-Tools/p2c` | **Live** | 1.21alpha2 |

---

## License

p2c is distributed under the [GNU General Public License](src/COPYING). The
generated C code and runtime files (`p2clib.c`, `p2c.h`) are **not** restricted
by the GPL.

---

*Research and fork maintenance as of March 2026.*
