#!/usr/bin/env bash
#
# Checks the host for the things an AOSP 16 build needs. Nothing here is
# installed for you; it only reports.
#
set -uo pipefail

ok=0
warn=0

say() { printf '%s %s\n' "$1" "$2"; }
good() { say "  ok  " "$1"; }
bad() { say " FAIL " "$1"; ok=1; }
soft() { say " warn " "$1"; warn=1; }

printf '\n[debkit] host check\n\n'

if [ "$(uname -s)" = "Linux" ]; then
  good "kernel: $(uname -sr)"
else
  bad "kernel: $(uname -s) - AOSP only builds on Linux (use a Linux box, VM or container)"
fi

case "$(uname -m)" in
  x86_64|aarch64) good "host arch: $(uname -m)" ;;
  *) bad "host arch: $(uname -m) - need x86_64 or aarch64" ;;
esac

mem_gb=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0) / 1024 / 1024 ))
if [ "$mem_gb" -ge 32 ]; then
  good "RAM: ${mem_gb} GiB"
elif [ "$mem_gb" -ge 16 ]; then
  soft "RAM: ${mem_gb} GiB - builds work with a small ccache but expect swapping"
else
  bad "RAM: ${mem_gb} GiB - 32 GiB or more is what AOSP wants"
fi

free_gb=$(df -BG --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')
free_gb=${free_gb:-0}
if [ "$free_gb" -ge 400 ]; then
  good "disk: ${free_gb} GiB free on /"
elif [ "$free_gb" -ge 250 ]; then
  soft "disk: ${free_gb} GiB free - enough for one target with ccache off, tight"
else
  bad "disk: ${free_gb} GiB free - AOSP 16 with out/ and ccache wants 400 GiB"
fi

for tool in git curl python3 unzip zip rsync ccache; do
  if command -v "$tool" >/dev/null 2>&1; then
    good "$tool: $(command -v "$tool")"
  else
    case "$tool" in
      ccache) soft "$tool: missing (optional but makes rebuilds much faster)" ;;
      *) bad "$tool: missing - sudo apt install $tool" ;;
    esac
  fi
done

if command -v repo >/dev/null 2>&1; then
  good "repo: $(command -v repo)"
else
  bad "repo: missing - see https://source.android.com/setup/develop#installing-repo"
fi

# AOSP 16 ships its own JDK in prebuilts/, so a host JDK is not required.
if command -v java >/dev/null 2>&1; then
  good "java: $(java -version 2>&1 | head -1)"
else
  soft "java: not on PATH - fine, prebuilts/jdk in the tree is used"
fi

if command -v debootstrap >/dev/null 2>&1; then
  good "debootstrap: $(command -v debootstrap) (needed by scripts/make-rootfs.sh)"
else
  soft "debootstrap: missing - sudo apt install debootstrap (only for ./build.sh rootfs)"
fi

printf '\n'
if [ "$ok" -ne 0 ]; then
  printf '[debkit] blockers above must be fixed before ./build.sh sync\n\n'
  exit 1
fi
if [ "$warn" -ne 0 ]; then
  printf '[debkit] warnings only - you can go ahead\n\n'
else
  printf '[debkit] all good\n\n'
fi
