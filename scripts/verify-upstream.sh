#!/usr/bin/env bash
#
# Verify that each upstream/* tag still reproduces its release archive: same
# files, same contents.
#
# Only files are compared, deliberately. Git cannot represent an empty
# directory, and 1.21alpha2's archive ships two of them (home/ and home/p2c/,
# for "make install" to fill), so a recursive diff calls them missing from the
# tag and fails. This script's first version did exactly that, and passed only
# because the worktree happened to hold a leftover ignored home/ from an
# earlier build: right answer, wrong reason. Anyone reaching for "diff -r"
# here will reintroduce that.
#
# Modes and symlinks are not compared, so "reproduces" means contents.
#
# Usage: verify-upstream.sh <git-worktree> <lineage-dir>
#   Produce the lineage directory with fetch-upstream-lineage.sh, which reads
#   from the archive branch and so needs no network.

set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=scripts/lineage-releases.sh
. "$here/lineage-releases.sh"

wt="${1:?usage: verify-upstream.sh <git-worktree> <lineage-dir>}"
lineage="${2:?usage: verify-upstream.sh <git-worktree> <lineage-dir>}"

# Digest every file under a directory, as "hash  relative/path", sorted by
# path. .git is excluded in both forms: in a linked worktree it is a file, not
# a directory.
digests() {
  ( cd "$1" && find . -type f -not -path './.git' -not -path './.git/*' \
      -exec shasum -a 256 {} + | sort -k2 )
}

rc=0
for entry in "${LINEAGE_RELEASES[@]}"; do
  IFS='|' read -r ver _ _ <<<"$entry"
  ref="upstream/$ver"
  dir="$lineage/x$ver"

  if [ ! -d "$dir" ]; then
    printf '  %-22s FAILED: %s not found; run fetch-upstream-lineage.sh\n' "$ref" "$dir" >&2
    rc=1
    continue
  fi

  if ! err=$(git -C "$wt" checkout -q "$ref" 2>&1); then
    printf '  %-22s FAILED: %s\n' "$ref" "$err" >&2
    rc=1
    continue
  fi

  # Capture both listings and check each one succeeded and is non-empty. Fed
  # straight into diff through process substitution, a failure inside either
  # (shasum missing, find erroring) went unnoticed: both sides came out empty,
  # diff called them equal, and every tag reported "OK: 0 files".
  if ! pristine=$(digests "$(lineage_root "$dir")") || [ -z "$pristine" ] \
     || ! tagged=$(digests "$wt") || [ -z "$tagged" ]; then
    printf '  %-22s FAILED: could not list and hash both trees\n' "$ref" >&2
    rc=1
    continue
  fi

  if ! delta=$(diff <(printf '%s\n' "$pristine") <(printf '%s\n' "$tagged")); then
    printf '  %-22s MISMATCH\n' "$ref"
    printf '%s\n' "$delta" | sed -n '1,10s/^/           /p'
    rc=1
  else
    n=$(printf '%s\n' "$tagged" | wc -l | tr -d ' ')
    printf '  %-22s OK: %s files identical to the archive\n' "$ref" "$n"
  fi
done

# The tags are only half of it: the upstream branch must be the vendor line
# those tags were cut from, ending at the last release. Without this check, a
# branch deleted, rewritten or pointed somewhere else entirely still passed.
branch="upstream"
branch_ok=1
if ! git -C "$wt" rev-parse -q --verify "refs/heads/$branch" >/dev/null; then
  printf '  %-22s FAILED: branch not present\n' "$branch" >&2
  branch_ok=0
else
  last=""
  for entry in "${LINEAGE_RELEASES[@]}"; do
    IFS='|' read -r ver _ _ <<<"$entry"
    last="upstream/$ver"
    if ! git -C "$wt" merge-base --is-ancestor "$last" "$branch" 2>/dev/null; then
      printf '  %-22s FAILED: %s is not in its history\n' "$branch" "$last" >&2
      branch_ok=0
    fi
  done
  if [ "$(git -C "$wt" rev-parse "$branch^{tree}")" != \
       "$(git -C "$wt" rev-parse "$last^{tree}")" ]; then
    printf '  %-22s FAILED: tip is not %s\n' "$branch" "$last" >&2
    branch_ok=0
  fi
fi
if [ "$branch_ok" -eq 1 ]; then
  printf '  %-22s OK: contains every release and ends at %s\n' "$branch" "$last"
else
  rc=1
fi

exit "$rc"
