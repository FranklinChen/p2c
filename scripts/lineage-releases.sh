# shellcheck shell=bash
# Shared data for the vendor-branch scripts. Sourced, not executed.
#
# Everything about "which p2c releases exist and where they came from" lives
# here, so adding a release is one line rather than an edit in four files. The
# checksums deliberately do NOT live here: they are read from SHA256SUMS on the
# archive branch, which is the artifact whose whole job is holding them.

# version | archive filename | path on the upstream site
# shellcheck disable=SC2034  # read by the scripts that source this file
LINEAGE_RELEASES=(
  "1.21alpha2|p2c-1.21alpha2.tar.gz|archive/p2c-1.21alpha2.tar.gz"
  "2.00|p2c-2.00.tar.gz|archive/p2c-2.00.tar.gz"
  "2.01|p2c-2.01.tar.gz|archive/p2c-2.01.tar.gz"
  "2.02|p2c-2.02.zip|p2c-2.02.zip"
)

# Mirrored for preservation but not part of the comparable lineage: a
# redundant compress(1) encoding of 1.21alpha2, and a snapshot of Dave
# Gillespie's home page.
# shellcheck disable=SC2034  # read by the scripts that source this file
LINEAGE_EXTRAS=(
  "p2c-1.21alpha2.tar.Z|archive/p2c-1.21alpha2.tar.Z"
  "daves.index-2012Jul25-20-44-55.html|archive/daves.index-2012Jul25-20-44-55.html"
)

# Schneider asks that https://alum.mit.edu/www/toms/p2c/ be treated as the
# canonical address, because he repoints it whenever hosting moves. It sits
# behind a bot filter that refuses command-line fetchers, so network fetches
# use the host it currently points at. If that stops resolving, open the
# canonical address in a browser to find where it went.
# shellcheck disable=SC2034  # read by the scripts that source this file
LINEAGE_SITE="http://users.fred.net/tds/lab/p2c"
# shellcheck disable=SC2034  # read by the scripts that source this file
LINEAGE_CANONICAL="https://alum.mit.edu/www/toms/p2c/"
LINEAGE_ARCHIVE_BRANCH="upstream-archives"

# The archive branch as a usable ref. A fresh CI checkout has it only as a
# remote-tracking ref, so prefer the local branch and fall back to origin's.
lineage_archive_ref() {
  if git rev-parse -q --verify "$LINEAGE_ARCHIVE_BRANCH" >/dev/null; then
    printf '%s\n' "$LINEAGE_ARCHIVE_BRANCH"
  else
    printf 'origin/%s\n' "$LINEAGE_ARCHIVE_BRANCH"
  fi
}

# The digest recorded for an archive, from the branch. Empty if unknown.
lineage_expected_sha() {
  git show "$(lineage_archive_ref):SHA256SUMS" 2>/dev/null \
    | awk -v f="$1" '$2 == f { print $1 }'
}

# Where a release's tree actually sits under its extraction directory.
#
# 2.00, 2.01 and 2.02 each unpack into a single top-level directory, whose name
# varies (2.02's is "p2c-2-ZIPPERDOT-02", because zip would not accept a dot).
# 1.21alpha2 is a tarbomb and unpacks in place. Deriving this removes both
# special cases, and a new release is covered whichever shape it takes.
lineage_root() {
  dir="$1"
  count=$(find "$dir" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
  if [ "$count" = "1" ]; then
    only=$(find "$dir" -mindepth 1 -maxdepth 1)
    if [ -d "$only" ]; then
      printf '%s\n' "$only"
      return
    fi
  fi
  printf '%s\n' "$dir"
}
