#!/usr/bin/env bash
#
# DebKit - an AOSP 16 tree that can install and run Debian .deb packages,
# debloated and built for arm64 (real hardware) and amd64 (emulator / x86 boxes).
#
#   ./build.sh env                 check the host can build AOSP
#   ./build.sh sync                repo init/sync AOSP 16 + link vendor/debkit
#   ./build.sh rootfs [arch]       build the Debian rootfs tarball(s)
#   ./build.sh build <arch> [var]  lunch + build (arch: arm64|amd64, var: userdebug|user)
#   ./build.sh both                build both architectures, userdebug
#   ./build.sh artifacts <arch>    collect images, ISO and binaries into dist/
#   ./build.sh publish <tag>       upload dist/ as a GitHub release
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOSP_DIR="${AOSP_DIR:-$HOME/aosp}"
AOSP_BRANCH="${AOSP_BRANCH:-android-16.0.0_r1}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 8)}"

log() { printf '\033[1;34m[debkit]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[debkit]\033[0m %s\n' "$*" >&2; exit 1; }

lunch_target() {
  case "$1" in
    arm64|aarch64) echo "debkit_arm64-$2" ;;
    amd64|x86_64|x64) echo "debkit_x86_64-$2" ;;
    *) die "unknown arch '$1' (use arm64 or amd64)" ;;
  esac
}

cmd_env() {
  "$REPO_DIR/scripts/check-env.sh"
}

cmd_sync() {
  "$REPO_DIR/scripts/fetch-aosp.sh" "$AOSP_DIR" "$AOSP_BRANCH"
  "$REPO_DIR/scripts/link-vendor.sh" "$REPO_DIR" "$AOSP_DIR"
}

cmd_rootfs() {
  local arch="${1:-both}"
  case "$arch" in
    both)
      "$REPO_DIR/scripts/make-rootfs.sh" arm64 "$REPO_DIR"
      "$REPO_DIR/scripts/make-rootfs.sh" amd64 "$REPO_DIR"
      ;;
    arm64|amd64)
      "$REPO_DIR/scripts/make-rootfs.sh" "$arch" "$REPO_DIR"
      ;;
    *) die "unknown arch '$arch' (use arm64, amd64 or both)" ;;
  esac
}

cmd_build() {
  local arch="${1:-arm64}" variant="${2:-userdebug}"
  [ -d "$AOSP_DIR/build/make" ] || die "no AOSP tree at $AOSP_DIR (run: $0 sync)"
  local target
  target="$(lunch_target "$arch" "$variant")"
  log "building $target"
  (
    cd "$AOSP_DIR"
    # shellcheck disable=SC1091
    source build/envsetup.sh
    lunch "$target"
    # The default target builds droid, which produces every image that matters
    # here (system, system_ext) plus debkitd and deb from PRODUCT_PACKAGES.
    m -j"$JOBS"
  )
  log "images in $AOSP_DIR/out/target/product/*/"
}

cmd_both() {
  cmd_build arm64 userdebug
  cmd_build amd64 userdebug
}

cmd_artifacts() {
  local arch="${1:-arm64}" variant="${2:-userdebug}"
  "$REPO_DIR/scripts/make-artifacts.sh" "$arch" "$variant" "$REPO_DIR"
}

cmd_publish() {
  local tag="${1:-}"
  [ -n "$tag" ] || die "usage: $0 publish <tag>   (e.g. $0 publish v1.0)"
  "$REPO_DIR/scripts/publish-release.sh" "$tag" "$REPO_DIR"
}

usage() {
  cat <<'EOF'
DebKit build driver

  ./build.sh env                  check the host (tools, RAM, disk)
  ./build.sh sync                 repo init/sync AOSP 16, link vendor/debkit
  ./build.sh rootfs [arch]        build Debian rootfs tarball(s): arm64|amd64|both
  ./build.sh build <arch> [var]   lunch + build (var: userdebug|user)
  ./build.sh both                 build arm64 and amd64 userdebug
  ./build.sh artifacts <arch>     collect images, live ISO and binaries into dist/
  ./build.sh publish <tag>        upload dist/ as a GitHub release

Environment:
  AOSP_DIR      where the AOSP tree lives      (default: $HOME/aosp)
  AOSP_BRANCH   AOSP tag/branch to sync        (default: android-16.0.0_r1)
  JOBS          parallel make jobs             (default: nproc)

The usual run, end to end:

  ./build.sh env && ./build.sh sync
  ./build.sh rootfs both
  ./build.sh build arm64 && ./build.sh artifacts arm64
  ./build.sh build amd64 && ./build.sh artifacts amd64
  ./build.sh publish v1.0

`publish` needs the GitHub CLI (gh auth login). Images are gigabytes, so they
go on the Releases page, not in git.
EOF
}

main() {
  local sub="${1:-help}"
  shift || true
  case "$sub" in
    env) cmd_env ;;
    sync) cmd_sync ;;
    rootfs) cmd_rootfs "${1:-both}" ;;
    build) cmd_build "${1:-arm64}" "${2:-userdebug}" ;;
    both) cmd_both ;;
    artifacts) cmd_artifacts "${1:-arm64}" "${2:-userdebug}" ;;
    publish) cmd_publish "${1:-}" ;;
    help|-h|--help) usage ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
