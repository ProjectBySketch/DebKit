#!/usr/bin/env bash
#
# Fetches an AOSP 16 (Baklava) tree. Defaults to the first stable release tag;
# set AOSP_BRANCH to android16-release or a specific android-16.0.0_rN to move.
#
set -euo pipefail

AOSP_DIR="${1:-$HOME/aosp}"
BRANCH="${2:-${AOSP_BRANCH:-android-16.0.0_r1}}"
MANIFEST="https://android.googlesource.com/platform/manifest"

log() { printf '\033[1;34m[debkit]\033[0m %s\n' "$*"; }

command -v repo >/dev/null 2>&1 || {
  echo "repo is not installed: https://source.android.com/setup/develop#installing-repo" >&2
  exit 1
}

mkdir -p "$AOSP_DIR"
cd "$AOSP_DIR"

if [ ! -d .repo ]; then
  log "repo init $BRANCH in $AOSP_DIR"
  # --partial-clone keeps the checkout to a sane size; blobs are fetched lazily.
  repo init -u "$MANIFEST" -b "$BRANCH" --partial-clone --clone-filter=blob:limit=10M
else
  log "existing checkout in $AOSP_DIR - syncing $BRANCH"
fi

log "repo sync (this is the long one: 150-250 GiB)"
repo sync -c -j"$(nproc)" --force-sync --no-tags --no-clone-bundle

log "AOSP tree ready at $AOSP_DIR"
