# amd64 (x86_64) DebKit product - the emulator target and x86 boxes.
#
# Same layering as debkit_arm64.mk: this only picks the base product.

DEBKIT_BASE_X86_64 ?= device/generic/x86_64/aosp_x86_64.mk

ifeq ($(wildcard $(DEBKIT_BASE_X86_64)),)
DEBKIT_BASE_X86_64 := device/generic/goldfish/sdk_phone_x86_64.mk
endif

ifeq ($(wildcard $(DEBKIT_BASE_X86_64)),)
$(error DebKit: no base product at $(DEBKIT_BASE_X86_64). Set DEBKIT_BASE_X86_64 to your x86_64 product makefile.)
endif

$(call inherit-product, $(DEBKIT_BASE_X86_64))
$(call inherit-product, vendor/debkit/debloat.mk)
$(call inherit-product, vendor/debkit/debkit_product.mk)

PRODUCT_NAME := debkit_x86_64
PRODUCT_BRAND := DebKit
PRODUCT_MODEL := DebKit amd64
PRODUCT_MANUFACTURER := DebKit
