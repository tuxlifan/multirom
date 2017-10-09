LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE:= trampoline_encmnt
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT)
LOCAL_UNSTRIPPED_PATH := $(TARGET_ROOT_OUT_UNSTRIPPED)
LOCAL_SHARED_LIBRARIES := libcutils libcrypto libhardware
LOCAL_STATIC_LIBRARIES := libmultirom_static
LOCAL_WHOLE_STATIC_LIBRARIES := libm libpng libz libscrypt_static libft2_mrom_static

LOCAL_C_INCLUDES += $(multirom_local_path) external/scrypt/lib/crypto external/boringssl/src/include

ifeq ($(TARGET_HW_DISK_ENCRYPTION),true)
    ifeq ($(TARGET_CRYPTFS_HW_PATH),)
        LOCAL_C_INCLUDES += device/qcom/common/cryptfs_hw
    else
        LOCAL_C_INCLUDES += $(TARGET_CRYPTFS_HW_PATH)
    endif
    LOCAL_SHARED_LIBRARIES += libcryptfs_hw
    LOCAL_CFLAGS += -DCONFIG_HW_DISK_ENCRYPTION
endif

LOCAL_SRC_FILES := \
    cryptfs.c \
    encmnt.c \
    pw_ui.c \
    ../rom_quirks.c \

include $(multirom_local_path)/device_defines.mk

include $(BUILD_EXECUTABLE)


ifeq ($(MR_ENCRYPTION_FAKE_PROPERTIES),true)
    include $(CLEAR_VARS)

    LOCAL_MODULE := libmultirom_fake_properties
    LOCAL_MODULE_TAGS := optional
    LOCAL_C_INCLUDES += $(multirom_local_path)

    LOCAL_SRC_FILES := fake_properties.c

    ifneq ($(MR_ENCRYPTION_FAKE_PROPERTIES_EXTRAS),)
        LOCAL_CFLAGS += -DMR_ENCRYPTION_FAKE_PROPERTIES_EXTRAS
        LOCAL_SRC_FILES += ../../../../$(MR_ENCRYPTION_FAKE_PROPERTIES_EXTRAS)
    endif

    include $(multirom_local_path)/device_defines.mk

    include $(BUILD_SHARED_LIBRARY)
endif
