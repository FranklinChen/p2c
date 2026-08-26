# scripts

Two groups. All are `bash`, and all pass `shellcheck` at default severity,
which CI enforces.

## Gates, run in CI

| Script | Purpose |
|---|---|
| `check-c23-output.sh` | Verify p2c's *generated* C is valid strict ISO C23, links, and runs correctly, over every example. Invoked as `make c23-check`, or as part of `make check`. |

`make test` builds generated code in the compiler's default dialect, which
still tolerates K&R function definitions, so it cannot answer whether p2c's
output is valid under a current standard. This can, and it fails rather than
skips when its inputs are missing.

## Archaeology, run by hand

These maintain the `upstream` and `upstream-archives` branches. You should not
normally need them: those branches already exist and upstream is not being
developed. They matter if upstream publishes something new, or if that host
finally disappears and the archives have to be re-sourced.

| Script | Purpose |
|---|---|
| `fetch-upstream-lineage.sh` | Download every surviving p2c archive, verify checksums, extract into the layout the others expect. Start here. |
| `lineage-diff.sh` | Show what actually changed between consecutive releases. |
| `build-upstream-branch.sh` | Rebuild the `upstream` branch and its `upstream/*` tags from extracted releases. |
| `verify-upstream.sh` | Confirm each tag reproduces its archive file for file. |

Typical run:

```bash
scripts/fetch-upstream-lineage.sh /tmp/lineage
scripts/lineage-diff.sh /tmp/lineage

git worktree add --detach /tmp/wt
scripts/verify-upstream.sh /tmp/wt /tmp/lineage
git worktree remove --force /tmp/wt
```

`verify-upstream.sh` compares file sets and file contents rather than running
`diff -r`, deliberately. Git cannot represent an empty directory, and p2c
1.21alpha2 ships two of them (`home/` and `home/p2c/`, for `make install` to
fill in), so a recursive diff reports them as missing from the tag and fails.
An earlier version of the script did exactly that, and passed only because the
worktree happened to hold a leftover ignored `home/` from a previous build:
right answer, wrong reason.

## Understanding the code

| Script | Purpose |
|---|---|
| `handler-census.sh` | Count the handlers registered with p2c's five `make*` constructors and report each one's declared arity. |

This exists because the `handler` field in `src/trans.h` holds five
differently-shaped function pointers that the compiler has never checked, and
because hand-written counts in that comment were twice wrong. Regenerate rather
than trust them.
