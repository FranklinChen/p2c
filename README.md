# p2c upstream distribution archives

Bit-exact copies of every p2c distribution archive known to survive, preserved
here because they exist in essentially one place on the public internet.

These are the files as downloaded, unmodified. The extracted contents of each
one are committed separately on the `upstream` branch, one commit per release,
tagged `upstream/<version>`. Use that branch to read or diff the sources; use
this branch to verify authenticity or to redistribute the originals.

## Contents

| File | Bytes | Released | Author |
|------|-------|----------|--------|
| `p2c-1.21alpha2.tar.gz` | 422648 | 1999-04-30 | Dave Gillespie |
| `p2c-1.21alpha2.tar.Z` | 621833 | 1999-05-27 | Dave Gillespie (repackaged by Schneider) |
| `p2c-2.00.tar.gz` | 575551 | 2015-10-05 | Thomas D. Schneider |
| `p2c-2.01.tar.gz` | 596466 | 2022-10-05 | Thomas D. Schneider |
| `p2c-2.02.zip` | 612752 | 2022-10-18 | Thomas D. Schneider |
| `daves.index-2012Jul25-20-44-55.html` | 8287 | snapshot 2012-07-25 | Dave Gillespie's home page, archived by Schneider |

`SHA256SUMS` carries checksums for all six. Verify with:

```bash
shasum -a 256 -c SHA256SUMS
```

The "Released" dates are the `Last-Modified` timestamps reported by the origin
server, not repackaging dates.

## Provenance

All six were retrieved on 2026-08-23 from Thomas Schneider's distribution site:

* `http://users.fred.net/tds/lab/p2c/p2c-2.02.zip`
* `http://users.fred.net/tds/lab/p2c/archive/<other files>`

Schneider asks that `https://alum.mit.edu/www/toms/p2c/` be treated as the
canonical address, since he repoints it whenever hosting moves. It has moved
many times: the original Caltech site (`csvax.cs.caltech.edu`) died in the
1990s, and `schneider.ncifcrf.gov` no longer resolves at all.

## Why this branch exists

p2c was written by Dave Gillespie between 1989 and 1993 and later maintained by
Thomas D. Schneider, who published 2.00, 2.01, and 2.02 before stepping back.
As of this writing the entire surviving lineage is served from a single host
running Apache 2.4.18. Every prior distribution point for this software has gone
dark, and there is no reason to assume this one will not.

These files are preserved so the record does not depend on one machine.

## License

p2c is distributed under the GNU General Public License. The generated C code
and the runtime files (`p2clib.c`, `p2c.h`) are not restricted by the GPL. See
the `COPYING` file inside each archive.
