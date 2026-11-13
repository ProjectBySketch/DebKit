#!/usr/bin/env bash
#
# Puts this repository into an AOSP tree as vendor/debkit.
#
# A symlink is used on purpose: you keep editing here, the build sees it there,
# and `repo sync` never fights over the files. If your build machine cannot
# follow symlinks (rare), pass --copy to put a real copy in place instead.
#
set -euo pipefail

REPO_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AOSP_DIR="${2:-${AOSP_DIR:-$HOME/aosp}}"
MODE="${3:-link}"

log() { printf '\033[1;34m[debkit]\033[0m %s\n' "$*"; }

[ -d "$AOSP_DIR/build/make" ] || { echo "no AOSP tree at $AOSP_DIR" >&2; exit 1; }
[ -d "$REPO_DIR/vendor/debkit" ] || { echo "no vendor/debkit in $REPO_DIR" >&2; exit 1; }

mkdir -p "$AOSP_DIR/vendor"
DEST="$AOSP_DIR/vendor/debkit"

if [ -L "$DEST" ] || [ -e "$DEST" ]; then
  log "removing old $DEST"
  rm -rf "$DEST"
fi

if [ "$MODE" = "copy" ]; then
  log "copying $REPO_DIR/vendor/debkit -> $DEST"
  cp -a "$REPO_DIR/vendor/debkit" "$DEST"
else
  log "linking $DEST -> $REPO_DIR/vendor/debkit"
  ln -s "$REPO_DIR/vendor/debkit" "$DEST"
fi

log "lunch targets now available:"
log "  debkit_arm64-userdebug    (arm64)"
log "  debkit_x86_64-userdebug   (amd64)"
log ""
log "start with:  cd $AOSP_DIR && source build/envsetup.sh && lunch debkit_arm64-userdebug"
