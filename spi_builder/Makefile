SRC ?= $(HOME)/gitlab/baikal-m
#CROSS ?= aarch64-unknown-linux-gnu-
#CROSS ?= aarch64-linux-gnu-
CROSS := $(HOME)/toolchains/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu-
SDK_VER = 4.4
BOARD ?= mitx
PLAT = bm1000

ifeq ($(BOARD),mitx)
	BE_TARGET = mitx
	BOARD_VER = 0
else ifeq ($(BOARD),mitx-d)
	BE_TARGET = mitx
	BOARD_VER = 2
#	DUAL_FLASH ?= yes
else ifeq ($(BOARD),e107)
	BE_TARGET = mitx
	BOARD_VER = 1
endif

DUAL_FLASH ?= no
UEFI_BUILD_TYPE ?= RELEASE
#UEFI_BUILD_TYPE = DEBUG
ARMTF_DEBUG ?= 0

SCP_BLOB = ./prebuilts/$(SDK_VER)/$(BE_TARGET).scp.flash.bin
UEFI_DIR ?= $(SRC)/uefi
ARMTF_DIR ?= $(SRC)/arm-tf
KDIR ?= $(SRC)/kernel

ARCH = arm64
NCPU := $(shell nproc)

DTB_DIR := $(CURDIR)/build
IMG_DIR := $(CURDIR)/img

TARGET_CFG = $(BE_TARGET)_defconfig
TARGET_DTB = baikal/bm-$(BOARD).dtb
KERNEL_FLAGS = O=$(DTB_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS) -C $(KDIR)

UEFI_FLAGS = $(UEFI_BUILD_TYPE)
ifeq ($(BE_TARGET),mitx)
	UEFI_FLAGS += -D BE_MITX=TRUE -D BOARD_VER=$(BOARD_VER)
endif

ifeq ($(ARMTF_DEBUG),0)
ARMTF_BUILD_TYPE=release
else
ARMTF_BUILD_TYPE=debug
endif

ARMTF_BUILD_DIR = $(ARMTF_DIR)/build/$(PLAT)/$(ARMTF_BUILD_TYPE)
BL1_BIN = $(ARMTF_BUILD_DIR)/bl1.bin
FIP_BIN = $(ARMTF_BUILD_DIR)/fip.bin

all: bootrom

# Note: BaseTools cannot be built in parallel.
basetools:
	$(MAKE) -C $(UEFI_DIR)/BaseTools

uefi $(IMG_DIR)/$(BOARD).efi.fd: basetools
	mkdir -p img
	rm -f $(IMG_DIR)/$(BOARD).efi.fd
	rm -rf $(UEFI_DIR)/Build
	UEFI_DIR=$(UEFI_DIR) CROSS=$(CROSS) UEFI_FLAGS="$(UEFI_FLAGS)" ./builduefi.sh
	cp $(UEFI_DIR)/Build/ArmBaikalBfkm-AARCH64/$(UEFI_BUILD_TYPE)_GCC6/FV/BFKM_EFI.fd $(IMG_DIR)/$(BOARD).efi.fd

arm-tf $(IMG_DIR)/$(BOARD).fip.bin $(IMG_DIR)/$(BOARD).bl1.bin: $(IMG_DIR)/$(BOARD).efi.fd
	rm -rf $(ARMTF_DIR)/build
	mkdir -p $(ARMTF_DIR)/build
	echo $(BOARD) > $(ARMTF_DIR)/build/subtarget
	$(MAKE) -j$(NCPU) CROSS_COMPILE=$(CROSS) BE_TARGET=$(BE_TARGET) BOARD_VER=$(BOARD_VER) DUAL_FLASH=$(DUAL_FLASH) PLAT=$(PLAT) DEBUG=$(ARMTF_DEBUG) LOAD_IMAGE_V2=0 -C $(ARMTF_DIR) all
	$(MAKE) -j$(NCPU) CROSS_COMPILE=$(CROSS) BE_TARGET=$(BE_TARGET) BOARD_VER=$(BOARD_VER) DUAL_FLASH=$(DUAL_FLASH) PLAT=$(PLAT) DEBUG=$(ARMTF_DEBUG) LOAD_IMAGE_V2=0 BL33=$(IMG_DIR)/$(BOARD).efi.fd -C $(ARMTF_DIR) fip
	cp $(FIP_BIN) $(IMG_DIR)/$(BOARD).fip.bin
	cp $(BL1_BIN) $(IMG_DIR)/$(BOARD).bl1.bin

bootrom: $(IMG_DIR)/$(BOARD).fip.bin $(IMG_DIR)/$(BOARD).bl1.bin $(IMG_DIR)/$(BOARD).dtb
	IMG_DIR=$(IMG_DIR) BOARD=$(BOARD) SCP_BLOB=$(SCP_BLOB) DUAL_FLASH=$(DUAL_FLASH) ./genrom.sh

dtb $(IMG_DIR)/$(BOARD).dtb: 
	mkdir -p $(DTB_DIR)
	$(MAKE) -j$(NCPU) $(KERNEL_FLAGS) $(TARGET_CFG)
	$(MAKE) -j$(NCPU) $(KERNEL_FLAGS) $(TARGET_DTB)
	cp $(DTB_DIR)/arch/$(ARCH)/boot/dts/$(TARGET_DTB) $(IMG_DIR)/$(BOARD).dtb

clean:
	rm -rf $(UEFI_DIR)/Build
	rm -rf $(DTB_DIR)
	rm -rf $(IMG_DIR)/$(BOARD).*
	$(MAKE) -C $(ARMTF_DIR) PLAT=bm1000 BE_TARGET=$(BE_TARGET) realclean
