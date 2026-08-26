#!/usr/bin/env bash
#
# Rebuild the pristine vendor line: one orphan branch holding the unmodified
# contents of each upstream release, one commit per release, each tagged.
#
# The point is diff hygiene. "git diff upstream/2.01 upstream/2.02" has to be
# exactly the upstream author's changes, with no fork-local edits mixed in, and
# main cannot provide that because it interleaves 1.21alpha2 with the Ubuntu
# patch series.
#
# It builds under a prefix that defaults to "upstream-rebuild", NOT "upstream",
# for two reasons. Git refuses "checkout --orphan" onto a branch that already
# exists, so aiming at the real branch would simply fail. And building beside
# it makes this a reproducibility check: the script finishes by comparing each
# rebuilt tree against the published tag, so you learn whether the vendor line
# can still be regenerated from the archives rather than merely trusting it.
#
# Usage: build-upstream-branch.sh <lineage-dir> <worktree-dir> [prefix]
#   Run from anywhere inside the repository. Produce the lineage directory with
#   fetch-upstream-lineage.sh. The worktree directory must not already exist.

set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=scripts/lineage-releases.sh
. "$here/lineage-releases.sh"

lineage="${1:?usage: build-upstream-branch.sh <lineage-dir> <worktree-dir> [prefix]}"
wt="${2:?usage: build-upstream-branch.sh <lineage-dir> <worktree-dir> [prefix]}"
prefix="${3:-upstream-rebuild}"

die() { echo "FATAL: $*" >&2; exit 1; }

repo=$(git rev-parse --show-toplevel) || die "not inside a git repository"
[ -e "$wt" ] && die "$wt already exists"

# Check every input up front. Without this a missing release directory would
# produce a commit and a tag over an empty tree, permanently recording the
# wrong thing on the branch that exists to prevent exactly that.
for entry in "${LINEAGE_RELEASES[@]}"; do
  IFS='|' read -r ver _ _ <<<"$entry"
  [ -d "$lineage/x$ver" ] || die "$lineage/x$ver not found; run fetch-upstream-lineage.sh"
done
git show-ref --verify --quiet "refs/heads/$prefix" \
  && die "branch $prefix already exists; delete it or choose another prefix"

git -C "$repo" worktree add --detach "$wt" >/dev/null 2>&1 || die "could not create worktree $wt"
git -C "$wt" checkout --orphan "$prefix" >/dev/null 2>&1 || die "could not create orphan branch $prefix"
git -C "$wt" rm -rq --cached . >/dev/null 2>&1

for entry in "${LINEAGE_RELEASES[@]}"; do
  IFS='|' read -r ver archive path <<<"$entry"
  src=$(lineage_root "$lineage/x$ver")

  # Replace the tree wholesale so that files REMOVED between releases are
  # recorded as removals rather than lingering from the previous commit.
  find "$wt" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} + \
    || die "could not clear $wt"
  cp -R "$src/." "$wt/" || die "could not copy $src"

  # Taken from the archive that was just verified, so the commit message cannot
  # drift from the bytes it describes.
  size=$(wc -c < "$lineage/$archive" | tr -d ' ')
  sha=$(shasum -a 256 "$lineage/$archive" | cut -d' ' -f1)

  git -C "$wt" add -A -f >/dev/null || die "could not stage $ver"
  git -C "$wt" commit -q -F - <<MSG || die "could not commit $ver"
Import pristine p2c $ver

Unmodified contents of the upstream distribution archive, with no
fork-local changes. Imported so that diffs between adjacent $prefix/*
tags are exactly the upstream author's changes.

Archive:        $archive
Source:         $LINEAGE_SITE/$path
Canonical site: $LINEAGE_CANONICAL
Size:           $size bytes
SHA-256:        $sha

Release dates and provenance are recorded on the $LINEAGE_ARCHIVE_BRANCH
branch, which also holds this archive byte-exact.
MSG
  git -C "$wt" tag "$prefix/$ver" || die "could not tag $ver"
  echo "  committed $prefix/$ver"
done

# Reproducibility check: does the rebuild match what is published?
echo
echo "comparing rebuilt trees against the published tags:"
rc=0
for entry in "${LINEAGE_RELEASES[@]}"; do
  IFS='|' read -r ver _ _ <<<"$entry"
  if ! published=$(git -C "$repo" rev-parse -q --verify "upstream/$ver^{tree}"); then
    printf '  %-22s no published tag to compare against\n' "upstream/$ver"
    continue
  fi
  rebuilt=$(git -C "$wt" rev-parse "$prefix/$ver^{tree}")
  if [ "$published" = "$rebuilt" ]; then
    printf '  %-22s identical (%s)\n' "upstream/$ver" "${rebuilt:0:12}"
  else
    printf '  %-22s DIFFERS: published %s, rebuilt %s\n' \
           "upstream/$ver" "${published:0:12}" "${rebuilt:0:12}"
    rc=1
  fi
done

echo
echo "Worktree left at $wt on branch $prefix. When finished:"
echo "  git worktree remove --force $wt"
echo "  git branch -D $prefix && git tag -d $prefix/..."
exit "$rc"
