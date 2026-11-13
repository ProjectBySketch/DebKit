# DebKit product definition.
#
# Two products, one per architecture:
#   debkit_arm64   - real arm64 hardware
#   debkit_x86_64  - the emulator and x86_64 boxes (the "amd64" target)
#
# They differ only in which AOSP generic target they inherit; everything DebKit
# adds is shared in debkit_product.mk.

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/debkit_arm64.mk \
    $(LOCAL_DIR)/debkit_x86_64.mk

COMMON_LUNCH_CHOICES := \
    debkit_arm64-userdebug \
    debkit_arm64-user \
    debkit_x86_64-userdebug \
    debkit_x86_64-user
