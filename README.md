# DebKit

An AOSP 16 (Baklava) tree that runs Debian `.deb` packages, ships debloated, and
builds for **arm64** (real hardware) and **amd64** (emulator, x86 boxes).

Two products:

- `debkit_arm64` - arm64 device builds
- `debkit_x86_64` - the amd64 target, i.e. what you run in the emulator

## How .deb support works

No glibc-on-Android tricks, no reimplemented dpkg. DebKit gives the image a real
Debian userland and hands the work to it:

- `./build.sh rootfs` builds a minimal Debian (minbase) rootfs with
  `debootstrap`, including `dpkg`, `apt` and `qemu-user-static`, and packs it
  into `vendor/debkit/rootfs/prebuilt/rootfs-<arch>.tar.gz`.
- The tarball is embedded at `/system_ext/debkit/` in the image.
- `deb rootfs init` unpacks it into `/data/debkit/rootfs` on the device
  (first use; it takes a minute).
- `deb install foo.deb` copies the package into the rootfs and runs
  `dpkg -i` **inside the chroot**, with `/dev`, `/proc` and `/sys` bind-mounted.
  So `gz`, `xz` and `zstd` packages, dependencies, `preinst`/`postinst` and
  `dpkg --purge` all behave exactly as on Debian.

### arm and amd64 at once

`binfmt_misc` plus the `qemu-*-static` binaries inside the rootfs mean a package
for the *other* architecture still runs: an arm64 image runs amd64 `.debs`
through `qemu-x86_64-static`, and an amd64 image runs arm64 `.debs` through
`qemu-aarch64-static`. Check what the current image can do with `deb arch`.
Cross-arch packages are interpreted, so expect them to be noticeably slower;
install the native build of anything heavy.

## What "debloat" means here

`vendor/debkit/debloat.mk` filters the stock AOSP apps out of `PRODUCT_PACKAGES`
after the base product is inherited, and turns off the first-run noise:
browser, calendar, camera, clock, email, music, print stack, settings
intelligence, quick search, wallpaper and live-wallpaper pickers, bookmarks
providers, STK, WAPPush, Protips, Traceur; setup wizard disabled, checkin off,
verify-only dexopt so first boot is not a compiler job. `deb debloat` lists it on
the device, and `ro.debkit.debloat=1` marks the image.

To keep something, delete its line. To remove more, add the module name.
`filter-out` silently ignores names your tree does not have, so this list cannot
break a build across AOSP releases.

## Quick start

On a Linux host with `repo`, `git`, ~400 GiB free and 32 GiB of RAM:

```
./build.sh env                  # check the host first
./build.sh sync                 # repo init/sync AOSP 16 into $HOME/aosp
./build.sh rootfs both          # Debian rootfs for arm64 and amd64
./build.sh build arm64          # debkit_arm64-userdebug
./build.sh build amd64          # debkit_x86_64-userdebug
```

`sync` symlinks this repository into the tree as `vendor/debkit`, so you keep
editing here and the build sees it there. `AOSP_DIR` and `AOSP_BRANCH` override
the defaults (`$HOME/aosp`, `android-16.0.0_r1`).

## On the device

```
adb root
deb arch                        # host arch, rootfs state, cross-arch support
deb rootfs init                 # unpack the embedded rootfs (once)
deb install ./hello_2.10_arm64.deb
deb run hello
deb list
deb info hello
deb remove hello
deb shell
```

`deb shell` and `deb run` need a terminal, so they always run in-process; the
other commands go through `debkitd` (started at boot by init) when it is up, and
fall back to doing the work directly when it is not. `setprop ro.debkit.autostart
0` before boot keeps the daemon off entirely.

## Putting it on real hardware

DebKit is a product layer, not a device tree: it inherits whatever you point it
at and adds the `.deb` runtime on top. Set the base product to your device's:

```
DEBKIT_BASE_ARM64 := device/acme/widget/aosp_widget.mk
```

or `make -j32 DEBKIT_BASE_ARM64=device/acme/widget/aosp_widget.mk`. The default
is AOSP's generic arm64 target, which boots in the emulator but is not a phone
image.

## Where the built files come from

AOSP cannot be compiled on a phone, and an image set is gigabytes: the images,
the ISO and the binaries are **build outputs, not source**, so they live on the
repository's **Releases** page rather than in git. Two ways to fill it:

**On your own Linux machine** (`repo`, ~400 GiB free, 32 GiB RAM):

```
./build.sh env && ./build.sh sync
./build.sh rootfs both
./build.sh build arm64 && ./build.sh artifacts arm64
./build.sh build amd64 && ./build.sh artifacts amd64
./build.sh publish v1.0          # needs `gh auth login`
```

**Through GitHub Actions**, which does the same thing on a machine of yours:
`.github/workflows/build.yml` runs `env` -> `sync` -> both architectures ->
`artifacts`, uploads them as workflow artifacts and, when you ask for it,
publishes the release. It runs on a **self-hosted** runner because a hosted
runner has neither the disk nor the hours:

```
# on the build machine, once
./config.sh --labels self-hosted,linux,aosp
```

Then *Actions -> build -> Run workflow*, tick `publish`, and the release appears.
Each `dist/debkit-<arch>-<variant>/` holds:

- `*.img` - every image the build made (system, boot, system_ext, super, ...)
- `debkit-<arch>-<variant>.zip` - unzip and `fastboot flashall`
- `debkit-amd64.iso` - bootable live medium for amd64
- `bin/debkitd`, `bin/rootfs-<arch>.tar.gz` - the runtime and its Debian userland
- `manifest.txt`, `SHA256SUMS` - what it is, and how to verify it

Assets over GitHub's 2 GiB limit are split into `.partNN` pieces; join them with
`cat name.part* > name`.

## Layout

- `build.sh` - the driver: `env`, `sync`, `rootfs`, `build`, `both`, `artifacts`, `publish`
- `scripts/` - host checks, AOSP sync, vendor link, rootfs, artifacts, release
- `.github/workflows/build.yml` - CI that builds and publishes on your runner
- `vendor/debkit/AndroidProducts.mk` - the two lunch targets
- `vendor/debkit/debkit_arm64.mk`, `debkit_x86_64.mk` - base product + layer
- `vendor/debkit/debkit_product.mk` - packages, rootfs embedding, properties
- `vendor/debkit/debloat.mk` - what is stripped
- `vendor/debkit/debkitd/` - the daemon and CLI (`debkitd`, `deb`)
- `vendor/debkit/sepolicy/` - the `debkitd` domain

## Status

The source is written and reviewed; the images have not been built yet. There is
no AOSP tree or compiler on the device this was authored on, so the first
`./build.sh sync` / `./build.sh build` (or the first CI run) is where the build
gets proven. The SELinux policy is deliberately `permissive debkitd` bring-up
policy - it is the piece most likely to need adjusting against a real device,
and the piece to tighten before shipping.
