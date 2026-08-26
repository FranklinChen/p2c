#!/usr/bin/env bash
# Build a pristine vendor line for p2c: one orphan branch holding the unmodified
# contents of each upstream release, one commit per release, each tagged.
#
# The point of the branch is diff hygiene: `git diff upstream/2.01 upstream/2.02`
# must be exactly the upstream author's changes, with no fork-local edits mixed in.
# main/ already interleaves 1.21alpha2 with the Ubuntu patch series, which is why
# this cannot simply be grafted onto existing history.
#
# Produce the lineage directory with fetch-upstream-lineage.sh first, and
# confirm the result with verify-upstream.sh afterwards.
#
# Usage: build-upstream-branch.sh <repo> <lineage-dir> <worktree-dir> <retrieved-date>
set -uo pipefail

repo="${1:?repo}"
lineage="${2:?lineage dir}"
wt="${3:?worktree dir}"
retrieved="${4:?retrieved date}"

# release | source subdirectory under lineage | archive filename | upstream author | release date | size | sha256
releases=(
"1.21alpha2|x1.21alpha2|p2c-1.21alpha2.tar.gz|Dave Gillespie|1999-04-30|422648|78a9a19c22d7a1a2b98d6c0394e36a6f42140f574018a69bfc4eebc7ce0b7a3b"
"2.00|x2.00/p2c-2.00|p2c-2.00.tar.gz|Thomas D. Schneider|2015-10-05|575551|f0cd9bc022188d7538880171d34a7e821a74cff081b55a94ff9c8a5403255f18"
"2.01|x2.01/p2c-2.01|p2c-2.01.tar.gz|Thomas D. Schneider|2022-10-05|596466|07db8f021aeb699b104d0713126eda0e46841248c47256ff6ecfdd2fd9ffb267"
"2.02|x2.02/p2c-2-ZIPPERDOT-02|p2c-2.02.zip|Thomas D. Schneider|2022-10-18|612752|baa322b12e477af38c767be0406b5e7ca2fa4c26ae2f80f4bc2889bf36d0069f"
)

base_url="http://users.fred.net/tds/lab/p2c"

# A fresh worktree keeps the user's working tree untouched.
git -C "$repo" worktree add --detach "$wt" >/dev/null 2>&1 || {
  echo "FATAL: could not create worktree at $wt" >&2; exit 1; }

git -C "$wt" checkout --orphan upstream >/dev/null 2>&1 || {
  echo "FATAL: could not create orphan branch 'upstream'" >&2; exit 1; }
git -C "$wt" rm -rq --cached . >/dev/null 2>&1
find "$wt" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +

for entry in "${releases[@]}"; do
  IFS='|' read -r ver srcdir archive author reldate size sha <<<"$entry"

  # Replace the tree wholesale so removals between releases are recorded too.
  find "$wt" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  # shellcheck disable=SC2086  # srcdir is a controlled literal, no globbing intended
  cp -R "$lineage/$srcdir/." "$wt/"

  # Archives for the older releases live under archive/ on the upstream site.
  if [ "$ver" = "2.02" ]; then url="$base_url/$archive"; else url="$base_url/archive/$archive"; fi

  git -C "$wt" add -A -f >/dev/null
  git -C "$wt" commit -q -F - <<MSG
Import pristine p2c $ver ($author, $reldate)

Unmodified contents of the upstream distribution archive, with no
fork-local changes. Imported so that diffs between adjacent upstream/*
tags are exactly the upstream author's changes.

Source:         $url
Canonical site: https://alum.mit.edu/www/toms/p2c/
Size:           $size bytes
SHA-256:        $sha
Retrieved:      $retrieved

Upstream author: $author
MSG
  git -C "$wt" tag "upstream/$ver"
  echo "committed + tagged upstream/$ver"
done

echo "---- upstream branch log:"
git -C "$wt" log --oneline upstream
