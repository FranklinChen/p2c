#!/usr/bin/env bash
# Compare consecutive pristine p2c releases to establish the real change history.
# diff exits non-zero when files differ, so pipefail/errexit are deliberately not used.
# Usage: lineage-diff.sh <lineage-dir>

root="${1:?usage: lineage-diff.sh <lineage-dir>}"
cd "$root" || exit 1

names=("1.21alpha2" "2.00" "2.01" "2.02")
dirs=(
  "x1.21alpha2"
  "x2.00/p2c-2.00"
  "x2.01/p2c-2.01"
  "x2.02/p2c-2-ZIPPERDOT-02"
)

for ((i = 1; i < ${#dirs[@]}; i++)); do
  prev="${dirs[i-1]}"
  cur="${dirs[i]}"
  echo "==== ${names[i-1]} -> ${names[i]}"

  listing=$(diff -rq "$prev" "$cur" 2>/dev/null)

  removed=$(printf '%s\n' "$listing" | grep -c "^Only in $prev")
  added=$(printf '%s\n' "$listing" | grep -c "^Only in $cur")
  echo "     files removed: $removed   added: $added"
  printf '%s\n' "$listing" | grep "^Only in $cur" | sed 's/^/     /' | head -6

  printf '%s\n' "$listing" | grep " differ$" | while read -r line; do
    left=${line#Files }
    left=${left%% and *}
    right=${line#* and }
    right=${right% differ}
    rel=${left#"$prev"/}
    n=$(diff "$left" "$right" 2>/dev/null | grep -c '^[<>]')
    printf '   %5s  %s\n' "$n" "$rel"
  done | sort -rn | head -10
done
