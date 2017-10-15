LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)

install_zip_path := $(multirom_local_path)/install_zip

MULTIROM_ZIP_TARGET := $(PRODUCT_OUT)/multirom
MULTIROM_INST_DIR := $(PRODUCT_OUT)/multirom_installer
multirom_binary := $(TARGET_ROOT_OUT)/multirom
trampoline_binary := $(TARGET_ROOT_OUT)/trampoline

ifeq ($(MR_FSTAB),)
    $(info MR_FSTAB not defined in device files)
endif

multirom_extra_dep :=
ifeq ($(MR_ENCRYPTION),true)
	multirom_extra_dep += trampoline_encmnt linker

	ifeq ($(MR_ENCRYPTION_FAKE_PROPERTIES),true)
		multirom_extra_dep += libmultirom_fake_properties
	else
		MR_ENCRYPTION_FAKE_PROPERTIES := false
	endif
else
	MR_ENCRYPTION := false
	MR_ENCRYPTION_FAKE_PROPERTIES := false
endif

MR_DEVICES := $(TARGET_DEVICE)
ifneq ($(MR_DEVICE_VARIANTS),)
	MR_DEVICES += $(MR_DEVICE_VARIANTS)
endif

$(MULTIROM_ZIP_TARGET): multirom trampoline bbootimg mrom_kexec_static mrom_adbd $(multirom_extra_dep)
	@echo
	@echo
	@echo "A crowdfunding campaign for MultiROM took place in 2013. These people got perk 'The Tenth':"
	@echo "    * Bibi"
	@echo "    * flash5000"
	@echo "Thank you. See DONORS.md in MultiROM's folder for more informations."
	@echo
	@echo

	@echo ----- Making MultiROM ZIP installer ------
	rm -rf $(MULTIROM_INST_DIR)
	mkdir -p $(MULTIROM_INST_DIR)
	cp -a $(install_zip_path)/prebuilt-installer/* $(MULTIROM_INST_DIR)/
	cp -a $(TARGET_ROOT_OUT)/multirom $(MULTIROM_INST_DIR)/multirom/
	cp -a $(TARGET_ROOT_OUT)/trampoline $(MULTIROM_INST_DIR)/multirom/
	cp -a $(TARGET_OUT_OPTIONAL_EXECUTABLES)/mrom_kexec_static $(MULTIROM_INST_DIR)/multirom/kexec
	cp -a $(TARGET_OUT_OPTIONAL_EXECUTABLES)/mrom_adbd $(MULTIROM_INST_DIR)/multirom/adbd

	if $(MR_ENCRYPTION); then \
		mkdir -p $(MULTIROM_INST_DIR)/multirom/enc/res; \
		cp -a $(TARGET_ROOT_OUT)/trampoline_encmnt $(MULTIROM_INST_DIR)/multirom/enc/; \
		\
		if [ "$(TARGET_IS_64_BIT)" == "true" ]; then \
			cp -a $(TARGET_OUT_EXECUTABLES)/linker64 $(MULTIROM_INST_DIR)/multirom/enc/; \
			echo "Relinking /system/bin/linker64 to /mrom_enc/linker64"; \
			sed -i "s|/system/bin/linker64\x0|/mrom_enc/linker64\x0\x0\x0|g" $(MULTIROM_INST_DIR)/multirom/enc/trampoline_encmnt; \
		else \
			cp -a $(TARGET_OUT_EXECUTABLES)/linker $(MULTIROM_INST_DIR)/multirom/enc/; \
			echo "Relinking /system/bin/linker to /mrom_enc/linker"; \
			sed -i "s|/system/bin/linker\x0|/mrom_enc/linker\x0\x0\x0|g" $(MULTIROM_INST_DIR)/multirom/enc/trampoline_encmnt; \
		fi; \
		\
		cp -a $(install_zip_path)/prebuilt-installer/multirom/res/Roboto-Regular.ttf $(MULTIROM_INST_DIR)/multirom/enc/res/; \
		\
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libcrypto.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libc.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libcutils.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libdl.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libhardware.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/liblog.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libm.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libstdc++.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libc++.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		if $(MR_ENCRYPTION_FAKE_PROPERTIES); then \
			cp -a $(TARGET_OUT_SHARED_LIBRARIES)/libmultirom_fake_properties.so $(MULTIROM_INST_DIR)/multirom/enc/; \
		fi; \
		if [ -n "$(MR_ENCRYPTION_SETUP_SCRIPT)" ]; then sh "$(ANDROID_BUILD_TOP)/$(MR_ENCRYPTION_SETUP_SCRIPT)" "$(ANDROID_BUILD_TOP)" "$(MULTIROM_INST_DIR)/multirom/enc"; fi; \
	fi

	mkdir $(MULTIROM_INST_DIR)/multirom/infos
	if [ -n "$(MR_INFOS)" ]; then cp -r $(PWD)/$(MR_INFOS)/* $(MULTIROM_INST_DIR)/multirom/infos/; fi
	cp -a $(TARGET_OUT_OPTIONAL_EXECUTABLES)/bbootimg $(MULTIROM_INST_DIR)/scripts/
	cp $(PWD)/$(MR_FSTAB) $(MULTIROM_INST_DIR)/multirom/mrom.fstab
	$(install_zip_path)/extract_boot_dev.sh $(PWD)/$(MR_FSTAB) $(MULTIROM_INST_DIR)/scripts/bootdev
	$(install_zip_path)/make_updater_script.sh "$(MR_DEVICES)" $(MULTIROM_INST_DIR)/META-INF/com/google/android "Installing MultiROM for"
	rm -f $(MULTIROM_ZIP_TARGET).zip $(MULTIROM_ZIP_TARGET)-unsigned.zip
	cd $(MULTIROM_INST_DIR) && zip -qr ../$(notdir $@)-unsigned.zip *
	java -jar $(multirom_local_path)/signapk/signapk.jar -w $(multirom_local_path)/signapk/jollaman999.x509.pem $(multirom_local_path)/signapk/jollaman999.pk8 $(MULTIROM_ZIP_TARGET)-unsigned.zip $(MULTIROM_ZIP_TARGET).zip
	$(install_zip_path)/rename_zip.sh $(MULTIROM_ZIP_TARGET) $(TARGET_DEVICE) $(PWD)/$(multirom_local_path)/version.h $(MR_DEVICE_SPECIFIC_VERSION)
	@echo ----- Made MultiROM ZIP installer -------- $@.zip

.PHONY: multirom_zip
multirom_zip: $(MULTIROM_ZIP_TARGET)



MULTIROM_UNINST_TARGET := $(PRODUCT_OUT)/multirom_uninstaller
MULTIROM_UNINST_DIR := $(PRODUCT_OUT)/multirom_uninstaller

$(MULTIROM_UNINST_TARGET): signapk bbootimg
	@echo ----- Making MultiROM uninstaller ------
	rm -rf $(MULTIROM_UNINST_DIR)
	mkdir -p $(MULTIROM_UNINST_DIR)
	cp -a $(install_zip_path)/prebuilt-uninstaller/* $(MULTIROM_UNINST_DIR)/
	cp -a $(TARGET_OUT_OPTIONAL_EXECUTABLES)/bbootimg $(MULTIROM_UNINST_DIR)/scripts/
	$(install_zip_path)/extract_boot_dev.sh $(PWD)/$(MR_FSTAB) $(MULTIROM_UNINST_DIR)/scripts/bootdev
	echo $(MR_RD_ADDR) > $(MULTIROM_UNINST_DIR)/scripts/rd_addr
	$(install_zip_path)/make_updater_script.sh "$(MR_DEVICES)" $(MULTIROM_UNINST_DIR)/META-INF/com/google/android "MultiROM uninstaller -"
	rm -f $(MULTIROM_UNINST_TARGET).zip $(MULTIROM_UNINST_TARGET)-unsigned.zip
	cd $(MULTIROM_UNINST_DIR) && zip -qr ../$(notdir $@)-unsigned.zip *
	java -jar $(multirom_local_path)/signapk/signapk.jar -w $(multirom_local_path)/signapk/jollaman999.x509.pem $(multirom_local_path)/signapk/jollaman999.pk8 $(MULTIROM_UNINST_TARGET)-unsigned.zip $(MULTIROM_UNINST_TARGET).zip
	@echo ----- Made MultiROM uninstaller -------- $@.zip

.PHONY: multirom_uninstaller
multirom_uninstaller: $(MULTIROM_UNINST_TARGET)
