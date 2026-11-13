# Everything DebKit adds to the image, shared by both architectures.
#
# This file is always included from vendor/debkit, so the paths below are
# relative to the top of the AOSP tree and the link made by scripts/link-vendor.sh.

# --- the .deb runtime -------------------------------------------------------
# Installs /system_ext/bin/debkitd and the `deb` symlink next to it.
PRODUCT_PACKAGES += \
    debkitd

# --- the Debian rootfs -----------------------------------------------------
# ./build.sh rootfs leaves a tarball behind; when it exists it is embedded in
# /system_ext/debkit/ and `deb rootfs init` unpacks it. Without it, push one to
# /data/debkit/rootfs-<arch>.tar.gz instead.
DEBKIT_ROOTFS_ARM64 := $(wildcard vendor/debkit/rootfs/prebuilt/rootfs-arm64.tar.gz)
DEBKIT_ROOTFS_AMD64 := $(wildcard vendor/debkit/rootfs/prebuilt/rootfs-amd64.tar.gz)

ifneq ($(DEBKIT_ROOTFS_ARM64),)
PRODUCT_COPY_FILES += \
    $(DEBKIT_ROOTFS_ARM64):$(TARGET_COPY_OUT_SYSTEM_EXT)/debkit/rootfs-arm64.tar.gz
endif

ifneq ($(DEBKIT_ROOTFS_AMD64),)
PRODUCT_COPY_FILES += \
    $(DEBKIT_ROOTFS_AMD64):$(TARGET_COPY_OUT_SYSTEM_EXT)/debkit/rootfs-amd64.tar.gz
endif

# --- init-time properties ---------------------------------------------------
PRODUCT_SYSTEM_EXT_PROPERTIES += \
    ro.debkit.version=1.0 \
    ro.debkit.debloat=true \
    ro.debkit.autostart=1

# --- SELinux ---------------------------------------------------------------
# system_ext private policy: the debkitd domain and its file types.
PRODUCT_PRIVATE_SEPOLICY_DIRS += vendor/debkit/sepolicy

# --- first boot is not a compiler job --------------------------------------
# Verify-only dexopt keeps the lightweight image out of a long first-boot
# dex2oat run; apps still get optimised in the background afterwards.
PRODUCT_PRODUCT_PROPERTIES += \
    pm.dexopt.first-boot=verify \
    pm.dexopt.boot-after-ota=verify
