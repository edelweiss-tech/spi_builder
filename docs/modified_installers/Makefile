CROSS = $(HOME)/toolchains/aarch64-unknown-linux-gnueabi/bin/aarch64-unknown-linux-gnueabi-

ARCH=arm64
B_DIR = $(CURDIR)/build
PKG_DIR = $(B_DIR)/package
BOOT_DIR = $(PKG_DIR)/boot

KDIR = $(HOME)/gitlab/baikal-m/kernel
ifeq ($(KERNEL),)
KERNEL = $(shell git -C $(KDIR) rev-parse --abbrev-ref HEAD)
endif
TARGET_NAME = mitx
TARGET_DTB = baikal/bm-mitx.dtb
TARGET_CFG = $(TARGET_NAME)_defconfig
#TARGET_CFG = tplatforms_mitx_defconfig
# Alt Linux
#INST_MOD_DIR = $(PKG_DIR)
# Debian 10 (buster)
INST_MOD_DIR = $(PKG_DIR)/usr
COMPRESSED=

NCPU := $(shell nproc)

ifeq ($(shell uname -m),aarch64)
CROSS_FLAGS = 
else
CROSS_FLAGS = ARCH=$(ARCH) CROSS_COMPILE=$(CROSS)
endif

ALL_FLAGS = O=$(B_DIR) $(CROSS_FLAGS) -C $(KDIR) -j$(NCPU) 
all: kernel modules package 
kernel: 
	mkdir -p $(B_DIR)
	$(MAKE) $(ALL_FLAGS) $(TARGET_CFG)
	$(MAKE) $(ALL_FLAGS)

dtb: 
	mkdir -p $(B_DIR)
	$(MAKE) $(ALL_FLAGS) $(TARGET_CFG)
	$(MAKE) $(ALL_FLAGS) $(TARGET_DTB)

perf: 
	mkdir -p $(B_DIR)/tools/perf
	$(MAKE) O=$(B_DIR)/tools/perf -j$(NCPU) $(CROSS_FLAGS) -C $(KDIR)/tools/perf

reconfigure: 
	mkdir -p $(B_DIR)
	$(MAKE) $(ALL_FLAGS) $(TARGET_CFG)
	$(MAKE) $(ALL_FLAGS) menuconfig
	$(MAKE) $(ALL_FLAGS) savedefconfig
	$(MAKE) $(ALL_FLAGS) 

modules:
	$(MAKE) $(ALL_FLAGS) modules
	mkdir -p $(INST_MOD_DIR)
	$(MAKE) $(ALL_FLAGS) modules_install INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=$(INST_MOD_DIR)

package:
	mkdir -p $(BOOT_DIR)
	cp $(B_DIR)/arch/arm64/boot/dts/$(TARGET_DTB) $(BOOT_DIR)/
	cp $(B_DIR)/arch/$(ARCH)/boot/$(COMPRESSED)/Image $(BOOT_DIR)/vmlinuz-$(TARGET_NAME).bin
	cp $(B_DIR)/.config $(BOOT_DIR)/config-$(TARGET_NAME)
	cp $(B_DIR)/System.map $(BOOT_DIR)/System.map-$(TARGET_NAME)
	tar --owner=0 --group=0 -caf package-$(ARCH)-$(KERNEL).tar.gz -C $(PKG_DIR) .

deb:
	mkdir -p deb
	$(MAKE) $(ALL_FLAGS) bindeb-pkg
	mv linux-* deb/

clean: clean
	make $(ALL_FLAGS) clean
