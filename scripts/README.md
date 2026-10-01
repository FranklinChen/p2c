# scripts

All are `bash` and all pass `shellcheck` at default severity, which CI
enforces. `lineage-releases.sh` is sourced by the others rather than run.

## Gates, run in CI

| Script | Checks |
|---|---|
| `check-c23-output.sh` | That p2c's *generated* C is valid strict ISO C23 and links, for every example, and that the three batch examples (fact, e, self) run correctly; cref and basic read stdin, so they are built but not run. Run it as `make c23-check`, or as part of `make check`. |
| `verify-upstream.sh` | That each `upstream/*` tag still reproduces its release archive, file for file, and that the `upstream` branch contains every release and ends at the last. |

Both fail rather than skip when their inputs are missing.

## Maintaining the vendor branches

`upstream` holds one pristine commit per upstream p2c release, tagged
`upstream/<version>`. `upstream-archives` holds the original distribution
files byte-exact, with `SHA256SUMS`. See the main [README](../README.md) for
why.

| Script | Purpose |
|---|---|
| `fetch-upstream-lineage.sh` | Materialise every release into a working directory, verified against `SHA256SUMS`. Reads from the archive branch by default, so no network. `--from-net` downloads instead, which is for adding a genuinely new release. |
| `lineage-diff.sh` | What actually changed between consecutive releases. |
| `build-upstream-branch.sh` | Rebuild the whole vendor line under a scratch prefix and compare it tree-by-tree against the published tags. |
| `lineage-releases.sh` | The release list, the upstream addresses, and the rule for locating a release inside its archive. Sourced by the three above and by `verify-upstream.sh`. |

```bash
scripts/fetch-upstream-lineage.sh /tmp/lineage
scripts/lineage-diff.sh /tmp/lineage
scripts/build-upstream-branch.sh /tmp/lineage /tmp/rebuild
```

Adding a release means putting its archive on `upstream-archives` with its
digest in `SHA256SUMS`, then adding one line to `lineage-releases.sh`.

### Two traps worth knowing

`verify-upstream.sh` compares file sets and contents rather than running
`diff -r`. Git cannot represent an empty directory, and 1.21alpha2 ships two
of them, so a recursive diff calls them missing from the tag and fails. The
first version of this script did that and *passed*, because the worktree
happened to hold a leftover ignored `home/` from an earlier build. Right
answer, wrong reason.

`build-upstream-branch.sh` builds under `upstream-rebuild`, not `upstream`.
Git refuses `checkout --orphan` onto a branch that exists, so a script aiming
at the real branch could never run at all. Building beside it and comparing
trees is both runnable and a stronger claim.

## Understanding the code

| Script | Purpose |
|---|---|
| `handler-census.sh` | Count the handlers registered with p2c's five `make*` constructors and report each one's declared arity. Run as `scripts/handler-census.sh src`. |

The `handler` field in `src/trans.h` holds five differently-shaped function
pointers the compiler has never checked. Hand-written counts in that comment
were wrong more than once, so regenerate rather than trust them.
