#!/usr/bin/env bash
#
# Fetch every surviving p2c distribution archive, verify it against the
# checksums recorded on the upstream-archives branch, and extract it into the
# layout the other lineage scripts expect.
#
# This is the entry point for the rest of the vendor tooling:
#
#   fetch-upstream-lineage.sh <dir>     download, verify, extract
#   lineage-diff.sh           <dir>     what changed between releases
#   build-upstream-branch.sh  ...       rebuild the upstream branch and tags
#   verify-upstream.sh        ...       confirm each tag matches its archive
#
# You should not normally need any of this: the upstream branch and its tags
# already exist, and upstream-archives holds the originals. It matters if
# upstream publishes something new, or if that host finally disappears and the
# archives have to be re-sourced from somewhere else.
#
# Usage: fetch-upstream-lineage.sh <target-dir>

set -uo pipefail

target="${1:?usage: fetch-upstream-lineage.sh <target-dir>}"

# Schneider asks that https://alum.mit.edu/www/toms/p2c/ be treated as the
# canonical address, because he repoints it when hosting moves. It sits behind
# a bot filter that refuses command-line fetchers, so this uses the host it
# currently points at. If that stops working, check the MIT address in a
# browser to find where it went.
base="http://users.fred.net/tds/lab/p2c"

# file | url path | sha256, as verified on 2026-08-23.
files=(
  "p2c-1.21alpha2.tar.gz|archive/p2c-1.21alpha2.tar.gz|78a9a19c22d7a1a2b98d6c0394e36a6f42140f574018a69bfc4eebc7ce0b7a3b"
  "p2c-1.21alpha2.tar.Z|archive/p2c-1.21alpha2.tar.Z|5529ced5d88b2242b4631747c688b58b9465fb69578d866020a4d28a6b2483ca"
  "p2c-2.00.tar.gz|archive/p2c-2.00.tar.gz|f0cd9bc022188d7538880171d34a7e821a74cff081b55a94ff9c8a5403255f18"
  "p2c-2.01.tar.gz|archive/p2c-2.01.tar.gz|07db8f021aeb699b104d0713126eda0e46841248c47256ff6ecfdd2fd9ffb267"
  "p2c-2.02.zip|p2c-2.02.zip|baa322b12e477af38c767be0406b5e7ca2fa4c26ae2f80f4bc2889bf36d0069f"
  "daves.index-2012Jul25-20-44-55.html|archive/daves.index-2012Jul25-20-44-55.html|6ccecc5d51770ae72dbc0d84a31892c5dbc214a9ad0101024df735e7654026f2"
)

mkdir -p "$target" || exit 1
cd "$target" || exit 1

failures=0
for entry in "${files[@]}"; do
  IFS='|' read -r name path want <<<"$entry"

  if [ ! -f "$name" ]; then
    printf 'fetching %s\n' "$name"
    if ! curl -sS -f --max-time 120 -o "$name" "$base/$path"; then
      printf '  FAILED to download %s/%s\n' "$base" "$path" >&2
      failures=$((failures + 1))
      continue
    fi
  fi

  got=$(shasum -a 256 "$name" | cut -d' ' -f1)
  if [ "$got" != "$want" ]; then
    printf '  CHECKSUM MISMATCH for %s\n    want %s\n    got  %s\n' "$name" "$want" "$got" >&2
    printf '  Refusing to use it. Either the file was corrupted in transit, or\n' >&2
    printf '  upstream replaced it, which is worth investigating before trusting.\n' >&2
    failures=$((failures + 1))
    continue
  fi
  printf '  %s verified\n' "$name"
done

if [ "$failures" -ne 0 ]; then
  echo "FAILED: $failures of ${#files[@]} archives" >&2
  exit 1
fi

# Extract into the directory names the other scripts expect. 1.21alpha2 has no
# top-level directory of its own; the rest do, and 2.02's is literally
# "p2c-2-ZIPPERDOT-02" because zip would not take a dot in the name.
echo "extracting"
rm -rf x1.21alpha2 x2.00 x2.01 x2.02
mkdir -p x1.21alpha2 x2.00 x2.01 x2.02
tar xzf p2c-1.21alpha2.tar.gz -C x1.21alpha2 || exit 1
tar xzf p2c-2.00.tar.gz       -C x2.00       || exit 1
tar xzf p2c-2.01.tar.gz       -C x2.01       || exit 1
unzip -q p2c-2.02.zip         -d x2.02       || exit 1

echo
echo "Ready. Extracted release trees:"
echo "  x1.21alpha2"
echo "  x2.00/p2c-2.00"
echo "  x2.01/p2c-2.01"
echo "  x2.02/p2c-2-ZIPPERDOT-02"
