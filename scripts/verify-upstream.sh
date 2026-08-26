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

  if ! delta=$(diff <(digests "$(lineage_root "$dir")") <(digests "$wt")); then
    printf '  %-22s MISMATCH\n' "$ref"
    printf '%s\n' "$delta" | sed -n '1,10s/^/           /p'
    rc=1
  else
    n=$(digests "$wt" | wc -l | tr -d ' ')
    printf '  %-22s OK: %s files identical to the archive\n' "$ref" "$n"
  fi
done

git -C "$wt" checkout -q upstream 2>/dev/null
exit "$rc"
