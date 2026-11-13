# arm64 (aarch64) DebKit product.
#
# The device tree it builds on top of. The default is AOSP's own generic arm64
# target, which boots in the emulator and on a handful of dev boards. To get
# DebKit on real hardware, point it at that device's product makefile, either in
# this file or on the command line:
#
#   DEBKIT_BASE_ARM64 := device/acme/widget/aosp_widget.mk
#   make -j32 DEBKIT_BASE_ARM64=device/acme/widget/aosp_widget.mk
#
# The board config, kernel, HALs and ABI come from there; DebKit only adds the
# .deb runtime, the rootfs and the debloat list.
DEBKIT_BASE_ARM64 ?= device/generic/arm64/aosp_arm64.mk

ifeq ($(wildcard $(DEBKIT_BASE_ARM64)),)
# Some trees only carry the goldfish/sdk variant of the generic arm64 target.
DEBKIT_BASE_ARM64 := device/generic/goldfish/sdk_phone_arm64.mk
endif

ifeq ($(wildcard $(DEBKIT_BASE_ARM64)),)
$(error DebKit: no base product at $(DEBKIT_BASE_ARM64). Set DEBKIT_BASE_ARM64 to your device's product makefile.)
endif

$(call inherit-product, $(DEBKIT_BASE_ARM64))
$(call inherit-product, vendor/debkit/debloat.mk)
$(call inherit-product, vendor/debkit/debkit_product.mk)

# PRODUCT_DEVICE stays whatever the base product set: DebKit is a layer, not a
# device tree.
PRODUCT_NAME := debkit_arm64
PRODUCT_BRAND := DebKit
PRODUCT_MODEL := DebKit arm64
PRODUCT_MANUFACTURER := DebKit
