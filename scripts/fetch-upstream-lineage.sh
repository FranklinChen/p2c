#!/usr/bin/env bash
#
# Materialise every surviving p2c release into a directory the other lineage
# scripts can work with, verifying each archive against the digests recorded on
# the upstream-archives branch.
#
# By default the archives come from that branch, not the network. They are
# already in this repository, byte-exact, which is the entire reason the branch
# exists: upstream is served from one aging host that has moved many times, and
# every previous p2c distribution site has gone dark. Reading them locally also
# means this works offline and in CI.
#
# Pass --from-net to download instead. That is for one case: upstream has
# published something new, and you are about to add it to the branch.
#
# Usage: fetch-upstream-lineage.sh [--from-net] <target-dir>

set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=scripts/lineage-releases.sh
. "$here/lineage-releases.sh"

from_net=0
target=""
for arg in "$@"; do
  case "$arg" in
    --from-net) from_net=1 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *)  target="$arg" ;;
  esac
done
[ -n "$target" ] || { echo "usage: $0 [--from-net] <target-dir>" >&2; exit 2; }

mkdir -p "$target" || exit 1
target=$(cd "$target" && pwd)

failures=0

# Put one archive in place and check it against the recorded digest.
obtain() {
  name="$1"
  path="$2"
  want=$(lineage_expected_sha "$name")

  if [ -z "$want" ]; then
    printf '  %-38s NO RECORDED DIGEST\n' "$name" >&2
    printf '      Not listed in %s:SHA256SUMS. If this is a new release, add\n' \
           "$LINEAGE_ARCHIVE_BRANCH" >&2
    printf '      it to that branch before trusting it.\n' >&2
    failures=$((failures + 1))
    return
  fi

  if [ ! -f "$target/$name" ]; then
    if [ "$from_net" = "1" ]; then
      if ! curl -sS -f --max-time 120 -o "$target/$name" "$LINEAGE_SITE/$path"; then
        printf '  %-38s DOWNLOAD FAILED\n' "$name" >&2
        printf '      %s/%s did not answer. That host has moved before;\n' \
               "$LINEAGE_SITE" "$path" >&2
        printf '      open %s in a browser to find where it went.\n' "$LINEAGE_CANONICAL" >&2
        failures=$((failures + 1))
        return
      fi
    elif ! git show "$(lineage_archive_ref):$name" > "$target/$name" 2>/dev/null; then
      rm -f "$target/$name"
      printf '  %-38s NOT ON %s\n' "$name" "$LINEAGE_ARCHIVE_BRANCH" >&2
      printf '      Fetch that branch, or pass --from-net to download it.\n' >&2
      failures=$((failures + 1))
      return
    fi
  fi

  got=$(shasum -a 256 "$target/$name" | cut -d' ' -f1)
  if [ "$got" != "$want" ]; then
    printf '  %-38s DIGEST MISMATCH\n' "$name" >&2
    printf '      want %s\n      got  %s\n' "$want" "$got" >&2
    printf '      Refusing to use it. Either it was corrupted, or upstream\n' >&2
    printf '      replaced a published file, which is worth investigating.\n' >&2
    failures=$((failures + 1))
    return
  fi
  printf '  %-38s verified\n' "$name"
}

if [ "$from_net" = "1" ]; then
  printf 'Fetching from %s\n' "$LINEAGE_SITE"
else
  printf 'Reading from the %s branch\n' "$LINEAGE_ARCHIVE_BRANCH"
fi

for entry in "${LINEAGE_RELEASES[@]}"; do
  IFS='|' read -r _ name path <<<"$entry"
  obtain "$name" "$path"
done
for entry in "${LINEAGE_EXTRAS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  obtain "$name" "$path"
done

if [ "$failures" -ne 0 ]; then
  echo "FAILED: $failures archive(s)" >&2
  exit 1
fi

# Extract each release into xVER/. Where its tree sits inside that is derived,
# not hard-coded; see lineage_root.
echo "extracting"
for entry in "${LINEAGE_RELEASES[@]}"; do
  IFS='|' read -r ver name _ <<<"$entry"
  dir="$target/x$ver"
  rm -rf "$dir"
  mkdir -p "$dir" || exit 1
  case "$name" in
    *.zip) unzip -q "$target/$name" -d "$dir" || exit 1 ;;
    *)     tar xzf "$target/$name" -C "$dir"  || exit 1 ;;
  esac
  printf '  %-12s -> %s\n' "$ver" "$(lineage_root "$dir")"
done
