#
# Copyright (C) 2021 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Restrict the visibility of Android.bp files to improve build analysis time
$(call inherit-product-if-exists, vendor/google/products/sources_pixel.mk)

TARGET_LINUX_KERNEL_VERSION := $(RELEASE_KERNEL_BLUEJAY_VERSION)
# Keeps flexibility for kasan and ufs builds
TARGET_KERNEL_DIR ?= $(RELEASE_KERNEL_BLUEJAY_DIR)
TARGET_BOARD_KERNEL_HEADERS ?= $(RELEASE_KERNEL_BLUEJAY_DIR)/kernel-headers

$(call inherit-product-if-exists, vendor/google_devices/bluejay/prebuilts/device-vendor-bluejay.mk)
$(call inherit-product-if-exists, vendor/google_devices/gs101/prebuilts/device-vendor.mk)
$(call inherit-product-if-exists, vendor/google_devices/gs101/proprietary/device-vendor.mk)
$(call inherit-product-if-exists, vendor/google_devices/bluejay/proprietary/device-vendor.mk)
$(call inherit-product-if-exists, vendor/google_devices/bluejay/proprietary/bluejay/device-vendor-bluejay.mk)
$(call inherit-product-if-exists, vendor/google_devices/bluejay/proprietary/WallpapersBluejay.mk)

DEVICE_PACKAGE_OVERLAYS += device/google/bluejay/bluejay/overlay

include device/google/bluejay-sepolicy/bluejay-sepolicy.mk
include device/google/gs101/device-shipping-common.mk
include device/google/gs101/telephony/pktrouter.mk
include device/google/gs-common/bcmbt/bluetooth.mk
include device/google/gs-common/touch/stm/stm11.mk

# Fingerprint HAL
GOODIX_CONFIG_BUILD_VERSION := g7_trusty
$(call inherit-product-if-exists, vendor/goodix/udfps/configuration/udfps_common.mk)
ifeq ($(filter factory%, $(TARGET_PRODUCT)),)
$(call inherit-product-if-exists, vendor/goodix/udfps/configuration/udfps_shipping.mk)
else
$(call inherit-product-if-exists, vendor/goodix/udfps/configuration/udfps_factory.mk)
endif

# go/lyric-soong-variables
$(call soong_config_set,lyric,camera_hardware,bluejay)
$(call soong_config_set,lyric,tuning_product,bluejay)
$(call soong_config_set,google3a_config,target_device,bluejay)

# sysconfig XML from stock
PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/product-sysconfig-stock.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/sysconfig/product-sysconfig-stock.xml

# Init files
PRODUCT_COPY_FILES += \
	device/google/bluejay/conf/init.bluejay.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.bluejay.rc

# Recovery files
PRODUCT_COPY_FILES += \
	device/google/gs101/conf/init.recovery.device.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.bluejay.rc

# TODO: Remove this after boot is confirmed.
# insmod files. Kernel 5.10 prebuilts don't provide these yet, so provide our
# own copy if they're not in the prebuilts.
# TODO(b/369686096): drop this when 5.10 is gone.
ifeq ($(wildcard $(TARGET_KERNEL_DIR)/init.insmod.*.cfg),)
PRODUCT_COPY_FILES += \
	device/google/bluejay/init.insmod.bluejay.cfg:$(TARGET_COPY_OUT_VENDOR_DLKM)/etc/init.insmod.bluejay.cfg
endif

# NFC
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
	frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
	frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hcef.xml \
	frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.nxp.mifare.xml \
	frameworks/native/data/etc/android.hardware.nfc.uicc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.uicc.xml \
	frameworks/native/data/etc/android.hardware.nfc.ese.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.ese.xml

PRODUCT_PACKAGES += \
	$(RELEASE_PACKAGE_NFC_STACK) \
	Tag \
	android.hardware.nfc-service.st \
	NfcOverlayBluejay

# Shared Modem Platform
SHARED_MODEM_PLATFORM_VENDOR := lassen

# Shared Modem Platform
include device/google/gs-common/modem/modem_svc_sit/shared_modem_platform.mk

# SecureElement
PRODUCT_PACKAGES += \
	android.hardware.secure_element@1.2-service-gto

PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.se.omapi.ese.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.se.omapi.ese.xml \
	frameworks/native/data/etc/android.hardware.se.omapi.uicc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.se.omapi.uicc.xml

DEVICE_MANIFEST_FILE += \
	device/google/bluejay/nfc/manifest_se_bluejay.xml

# Increment the SVN for any official public releases
ifdef RELEASE_SVN_BLUEJAY
TARGET_SVN ?= $(RELEASE_SVN_BLUEJAY)
else
# Set this for older releases that don't use build flag
TARGET_SVN ?= 65
endif

# Set build properties for SMR builds
ifeq ($(RELEASE_IS_SMR), true)
    ifneq (,$(RELEASE_BASE_OS_BLUEJAY))
        PRODUCT_BASE_OS := $(RELEASE_BASE_OS_BLUEJAY)
    endif
endif

# Hide cutout overlays
PRODUCT_PACKAGES += \
    NoCutoutOverlay \
    AvoidAppsInCutoutOverlay

# SKU specific RROs
PRODUCT_PACKAGES += \
    SettingsOverlayGB17L \
    SettingsOverlayG1AZG \
    SettingsOverlayGB62Z \
    SettingsOverlayGX7AS

# GPS xml
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
    ifneq (,$(filter 6.1, $(TARGET_LINUX_KERNEL_VERSION)))
        PRODUCT_COPY_FILES += \
            device/google/bluejay/gps.6.1.xml.b3:$(TARGET_COPY_OUT_VENDOR)/etc/gnss/gps.xml
    else
        PRODUCT_COPY_FILES += \
            device/google/bluejay/gps.xml.b3:$(TARGET_COPY_OUT_VENDOR)/etc/gnss/gps.xml
    endif
else
    ifneq (,$(filter 6.1, $(TARGET_LINUX_KERNEL_VERSION)))
        PRODUCT_COPY_FILES += \
            device/google/bluejay/gps_user.6.1.xml.b3:$(TARGET_COPY_OUT_VENDOR)/etc/gnss/gps.xml
    else
        PRODUCT_COPY_FILES += \
            device/google/bluejay/gps_user.xml.b3:$(TARGET_COPY_OUT_VENDOR)/etc/gnss/gps.xml
    endif
endif

# This device is shipped with 32 (Android S V2)
PRODUCT_SHIPPING_API_LEVEL := 32

# Vibrator HAL
$(call soong_config_set,haptics,kernel_ver,v$(subst .,_,$(TARGET_LINUX_KERNEL_VERSION)))
ADAPTIVE_HAPTICS_FEATURE := adaptive_haptics_v1
ACTUATOR_MODEL := legacy_zlra_actuator

# Device features
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml

# Disable AVF Remote Attestation
PRODUCT_AVF_REMOTE_ATTESTATION_DISABLED := true

PRODUCT_VENDOR_PROPERTIES := $(filter-out ro.vendor.build.svn=% , $(PRODUCT_VENDOR_PROPERTIES))
