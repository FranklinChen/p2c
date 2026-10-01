#!/usr/bin/env bash
#
# Verify that p2c's generated C is valid strict ISO C23, and that the programs
# built from it produce correct results.
#
# This is deliberately stricter than "make test", which compiles p2c's default
# K&R-style output as gnu17, a dialect that still accepts it. Strict -std=c23
# does not, so this exercises the combination that a downstream on a current
# toolchain actually needs:
#
#   p2c -a          emit prototypes instead of K&R parameter lists
#   MainType int    emit a return type on main(), since implicit int has been
#                   invalid C since C99
#
# Neither is p2c's default, and MainType in particular is a single line buried
# in an 83KB sys.p2crc, so this check exists to keep the recipe working rather
# than merely written down.
#
# Usage: scripts/check-c23-output.sh [compiler] [install-root]
# Defaults: cc, and ./home. Run from the repository root after "make test".
# Normally invoked as "make c23-check" or "make check", which pass both.

set -euo pipefail

cc_bin="${1:-cc}"
# The install root. "make c23-check" passes $(P2CHOME), so the makefile
# decides it for every invocation the project itself makes; the default here
# only serves someone running the script by hand from the repository root. A
# wrong value fails loudly in the required-inputs check below rather than
# being papered over. Generated code says #include <p2c/p2c.h>, so this is the
# directory containing p2c/, not p2c/ itself.
home="${2:-home}"
root="$(pwd)"
p2c_bin="$root/p2c"
lib="$home/libp2c.a"

# A gate that can skip itself is not a gate: missing inputs are failures.
for required in "$p2c_bin" "$lib" "$home/p2c/p2c.h" "$root/examples/p2crc"; do
  if [ ! -e "$required" ]; then
    echo "FATAL: $required not found. Run 'make test' first." >&2
    exit 1
  fi
done

if ! command -v "$cc_bin" >/dev/null 2>&1; then
  echo "FATAL: compiler '$cc_bin' not found." >&2
  exit 1
fi

# Pick the flag that selects C23 on this compiler. It was called c2x while the
# standard was in draft, and GCC 13 and Clang 15/16 still only know that name;
# both spellings select the same language. Probing up front means a compiler
# too old for either is reported as a toolchain limitation rather than as a
# defect in p2c's output, which is what every case would otherwise look like.
std_flag=""
for candidate in -std=c23 -std=c2x; do
  if printf 'int main(void){return 0;}\n' \
        | "$cc_bin" "$candidate" -x c - -o /dev/null 2>/dev/null; then
    std_flag="$candidate"
    break
  fi
done
if [ -z "$std_flag" ]; then
  echo "FATAL: $cc_bin supports neither -std=c23 nor -std=c2x." >&2
  echo "       This check needs a C23-capable compiler (GCC 13+, Clang 15+)." >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Which examples exist is discovered from the filesystem, so a new example is
# covered automatically rather than needing this list kept in step with the
# four copies in examples/Makefile and the root Makefile.
examples=""
for f in "$root"/examples/*.p; do
  examples="$examples $(basename "$f" .p)"
done

# Programs that read stdin are built and linked but never executed, otherwise
# they hang. The root Makefile's "test" target runs fact, e and self and
# likewise leaves these two alone, only suggesting them to the reader.
is_runnable() {
  case "$1" in
    cref)  return 1 ;;   # expects a list of files on stdin
    basic) return 1 ;;   # interactive BASIC interpreter
    *)     return 0 ;;
  esac
}

# How a runnable example is judged correct. An example with no case here still
# gets built, linked and run; it just has no output assertion.
verify_output() {
  case "$1" in
    fact) grep -qF "The factorial of 10 is 3628800" "$2" ;;
    e)    grep -qF "7182818284 5904523536" "$2" ;;
    # self prints its own source, so compare it exactly rather than sampling a
    # substring. This is the same check the root Makefile's "test" target makes.
    self) diff -q "$root/examples/self.p" "$2" >/dev/null 2>&1 ;;
    *)    return 0 ;;
  esac
}

printf 'Checking p2c output against strict ISO C23 (%s), using %s\n' \
  "$std_flag" "$cc_bin"
"$cc_bin" --version | sed -n '1s/^/  /p'

# Use the same p2crc "make test" uses, rather than synthesizing one. That keeps
# the dialect settings (Language HP, UseEnum, the FuncMacro block) identical to
# the real build, and means a regression in examples/p2crc is caught here
# instead of being masked. It is also where MainType int lives.
cp "$root/examples/p2crc" "$work/p2crc"

failures=0
checked=0

# Both take the stem, so the column width lives in one place. fail() optionally
# takes a file whose first lines are shown indented under the message.
ok() {
  printf '  %-6s OK     %s\n' "$1" "$2"
}
fail() {
  printf '  %-6s FAIL   %s\n' "$1" "$2"
  if [ -n "${3:-}" ] && [ -s "$3" ]; then
    # Errors first: compilers interleave warnings with them, and the warnings
    # are usually the longer half. Falls back to the head of the file when
    # the failure produced no line matching "error:".
    { grep 'error:' "$3" || cat "$3"; } | sed -n '1,5s/^/           /p'
  fi
  failures=$((failures + 1))
}

for stem in $examples; do
  checked=$((checked + 1))
  cp "$root/examples/$stem.p" "$work/"

  # p2c reads p2crc from its working directory. Its own failure is tested
  # explicitly: under errexit a bare failing call ended the whole script with
  # no FAIL line, no summary, and p2c's messages thrown away.
  if ! ( cd "$work" && "$p2c_bin" -a "$stem.p" ) >"$work/$stem.p2c.log" 2>&1; then
    fail "$stem" "p2c failed to translate it" "$work/$stem.p2c.log"
    continue
  fi

  if [ ! -f "$work/$stem.c" ]; then
    fail "$stem" "p2c produced no output"
    continue
  fi

  # -pedantic-errors turns any use of a non-C23 extension into a hard failure
  # rather than a warning, which is the entire point of this check.
  if ! "$cc_bin" "$std_flag" -pedantic-errors -I"$home" -c "$work/$stem.c" \
        -o "$work/$stem.o" 2> "$work/$stem.err"; then
    fail "$stem" "does not compile as strict C23" "$work/$stem.err"
    continue
  fi

  # Link the object just compiled rather than rebuilding from source, so the
  # dialect proven above is exactly the one linked.
  if ! "$cc_bin" "$work/$stem.o" "$lib" -lm -o "$work/$stem.bin" \
        2> "$work/$stem.link.err"; then
    fail "$stem" "compiles but does not link" "$work/$stem.link.err"
    continue
  fi

  if ! is_runnable "$stem"; then
    ok "$stem" "strict C23, links (not executed: reads stdin)"
    continue
  fi

  # Close stdin so a batch program can never hang waiting for input.
  if ! "$work/$stem.bin" </dev/null > "$work/$stem.out" 2>/dev/null; then
    fail "$stem" "linked, but exited non-zero when run"
    continue
  fi

  if ! verify_output "$stem" "$work/$stem.out"; then
    fail "$stem" "ran, but its output was not what we expect"
    continue
  fi

  ok "$stem" "strict C23, links, runs correctly"
done

if [ "$failures" -ne 0 ]; then
  echo "FAILED: $failures of $checked checks" >&2
  exit 1
fi

echo "All $checked checks passed."
