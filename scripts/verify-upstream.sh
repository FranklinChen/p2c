#!/usr/bin/env bash
#
# Verify that each upstream/* tag reproduces its pristine release archive
# exactly: same set of files, same contents.
#
# Directories are compared only through the files they contain, deliberately.
# Git cannot represent an empty directory, and p2c 1.21alpha2's archive ships
# two of them (home/ and home/p2c/, both empty, created for "make install" to
# fill in). A plain "diff -r" reports those as missing from the tag and fails,
# which is a limitation of git rather than a defect in the import.
#
# That distinction bit this script's first version, which used "diff -r" and
# passed only because the worktree happened to contain a leftover ignored
# home/ directory from an earlier build. It reported success for the wrong
# reason. Comparing file sets and file contents has no such failure mode.
#
# Usage: verify-upstream.sh <git-worktree> <lineage-dir>
#   The worktree must belong to this repository and is left on the upstream
#   branch. Produce the lineage directory with fetch-upstream-lineage.sh.

set -uo pipefail

wt="${1:?usage: verify-upstream.sh <git-worktree> <lineage-dir>}"
lineage="${2:?usage: verify-upstream.sh <git-worktree> <lineage-dir>}"

pairs=(
  "1.21alpha2|x1.21alpha2"
  "2.00|x2.00/p2c-2.00"
  "2.01|x2.01/p2c-2.01"
  "2.02|x2.02/p2c-2-ZIPPERDOT-02"
)

rc=0
for pair in "${pairs[@]}"; do
  IFS='|' read -r ver src <<<"$pair"
  ref="upstream/$ver"

  if [ ! -d "$lineage/$src" ]; then
    printf '  %-22s SKIPPED: %s not found\n' "$ref" "$lineage/$src" >&2
    rc=1
    continue
  fi

  if ! git -C "$wt" checkout -q "$ref" 2>/dev/null; then
    printf '  %-22s FAILED: no such tag\n' "$ref" >&2
    rc=1
    continue
  fi

  # File sets, relative and sorted. Skip .git, which in a linked worktree is a
  # file rather than a directory, so both forms have to be excluded.
  tagged=$( (cd "$wt" && find . -type f -not -path './.git' -not -path './.git/*' | sort) )
  pristine=$( (cd "$lineage/$src" && find . -type f | sort) )

  if [ "$tagged" != "$pristine" ]; then
    printf '  %-22s MISMATCH: file sets differ\n' "$ref"
    diff <(printf '%s\n' "$pristine") <(printf '%s\n' "$tagged") \
      | sed -n '1,10s/^/           /p'
    rc=1
    continue
  fi

  # Contents.
  differing=0
  while IFS= read -r f; do
    cmp -s "$wt/$f" "$lineage/$src/$f" || {
      [ "$differing" -lt 5 ] && printf '           differs: %s\n' "${f#./}"
      differing=$((differing + 1))
    }
  done <<<"$tagged"

  if [ "$differing" -ne 0 ]; then
    printf '  %-22s MISMATCH: %d file(s) differ\n' "$ref" "$differing"
    rc=1
  else
    n=$(printf '%s\n' "$tagged" | wc -l | tr -d ' ')
    printf '  %-22s OK: %s files identical to the archive\n' "$ref" "$n"
  fi
done

git -C "$wt" checkout -q upstream 2>/dev/null
exit "$rc"
