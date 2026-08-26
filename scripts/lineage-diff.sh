#!/usr/bin/env bash
#
# Show what actually changed between consecutive p2c releases.
#
# errexit and pipefail are deliberately not set: diff exits non-zero whenever
# files differ, which here is the normal case rather than a failure.
#
# Usage: lineage-diff.sh <lineage-dir>
#   Produce the lineage directory with fetch-upstream-lineage.sh.

set -u

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=scripts/lineage-releases.sh
. "$here/lineage-releases.sh"

lineage="${1:?usage: lineage-diff.sh <lineage-dir>}"

prev_ver=""
prev_dir=""
for entry in "${LINEAGE_RELEASES[@]}"; do
  IFS='|' read -r ver _ _ <<<"$entry"
  dir=$(lineage_root "$lineage/x$ver")

  if [ ! -d "$dir" ]; then
    echo "missing: $lineage/x$ver; run fetch-upstream-lineage.sh" >&2
    exit 1
  fi

  if [ -n "$prev_ver" ]; then
    echo "==== $prev_ver -> $ver"
    listing=$(diff -rq "$prev_dir" "$dir" 2>/dev/null)

    printf '     files removed: %s   added: %s\n' \
      "$(printf '%s\n' "$listing" | grep -c "^Only in $prev_dir")" \
      "$(printf '%s\n' "$listing" | grep -c "^Only in $dir")"
    printf '%s\n' "$listing" | grep "^Only in $dir" | sed 's/^/     /' | head -6

    # Files present on both sides, ranked by how much they changed. diff -rq
    # reports only that they differ, so the line counts need a second look at
    # each one.
    printf '%s\n' "$listing" \
      | sed -n "s|^Files $prev_dir/\(.*\) and .* differ\$|\1|p" \
      | while read -r rel; do
          printf '   %5s  %s\n' \
            "$(diff "$prev_dir/$rel" "$dir/$rel" | grep -c '^[<>]')" "$rel"
        done \
      | sort -rn | head -10
  fi

  prev_ver="$ver"
  prev_dir="$dir"
done
