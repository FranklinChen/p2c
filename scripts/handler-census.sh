#!/usr/bin/env bash
# Census every handler registered with p2c's five constructors and report the
# declared arity of each, to size what a typed-handler refactor would involve.
# PV() is p2c's zero-parameter prototype macro; PP( (...) ) carries the list.
set -uo pipefail
src="${1:?src dir}"

for ctor in makespecialproc makestandardproc makespecialfunc makestandardfunc makespecialvar; do
  names=$(grep -rho "$ctor *( *\"[^\"]*\" *, *[A-Za-z_][A-Za-z0-9_]*" "$src"/*.c \
          | sed 's/.*, *//' | sort -u | grep -v '^NULL$')
  total=0
  a0=0; a1=0; a2=0; unknown=0
  for n in $names; do
    proto=$(grep -hE "(\*|[^A-Za-z_])${n}[[:space:]]+P[PV]\(" "$src/p2c.proto" | head -1)
    total=$((total + 1))
    case "$proto" in
      *"PV()"*) a0=$((a0 + 1)) ;;
      *"PP( ("*)
        args=${proto#*PP( (}; args=${args%%)*}
        case $(printf '%s' "$args" | awk -F, '{print NF}') in
          1) a1=$((a1 + 1)) ;;
          2) a2=$((a2 + 1)) ;;
          *) unknown=$((unknown + 1)) ;;
        esac ;;
      *) unknown=$((unknown + 1)) ;;
    esac
  done
  printf '%-18s %3d handlers:  0-param=%-3d 1-param=%-3d 2-param=%-3d unknown=%d\n' \
         "$ctor" "$total" "$a0" "$a1" "$a2" "$unknown"
done
