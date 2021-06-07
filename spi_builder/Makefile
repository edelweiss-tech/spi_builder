PWD := $(shell pwd)
SRC ?= $(HOME)/gitlab/baikal-m
#CROSS ?= aarch64-unknown-linux-gnu-
#CROSS ?= aarch64-linux-gnu-
CROSS := $(HOME)/toolchains/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu-
# SDK_VER = 4.4
SDK_VER ?= 5.1
SDK_REV = 1
BOARD ?= mitx-d
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
ifeq ($(SDK_VER),4.4)
	UEFI_DIR ?= $(SRC)/uefi
else
	UEFI_DIR = $(PWD)/uefi
endif
ARMTF_DIR ?= $(SRC)/arm-tf
KDIR ?= $(SRC)/kernel

ARCH = arm64
NCPU := $(shell nproc)

DTB_DIR := $(CURDIR)/build
IMG_DIR := $(CURDIR)/img

TARGET_CFG = $(BE_TARGET)_defconfig
TARGET_DTB = baikal/bm-$(BOARD).dtb
KERNEL_FLAGS = O=$(DTB_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS) -C $(KDIR)

ifeq ($(SDK_VER),4.4)
else
	UEFI_FLAGS = -DFIRMWARE_VERSION_STRING=$(SDK_VER) -DFIRMWARE_REVISION=$(SDK_REV)
	UEFI_FLAGS += -DFIRMWARE_VENDOR=\"Edelweiss\"
endif
ifeq ($(BE_TARGET),mitx)
	UEFI_FLAGS += -DBE_MITX=TRUE -DBOARD_VER=$(BOARD_VER)
endif

ifeq ($(ARMTF_DEBUG),0)
ARMTF_BUILD_TYPE=release
else
ARMTF_BUILD_TYPE=debug
endif

ARMTF_BUILD_DIR = $(ARMTF_DIR)/build/$(PLAT)/$(ARMTF_BUILD_TYPE)
BL1_BIN = $(ARMTF_BUILD_DIR)/bl1.bin
FIP_BIN = $(ARMTF_BUILD_DIR)/fip.bin

all: setup bootrom

setup:
ifeq ($(SDK_VER),4.4)
else
	if [ ! -d uefi ]; then \
	mkdir uefi; \
	cd $(UEFI_DIR); \
	git clone http://github.com/tianocore/edk2.git; \
	git clone https://github.com/tianocore/edk2-non-osi.git; \
	git clone git@gitlab.tpl:baikal-m/edk2-platform-baikal.git; \
	cd $(UEFI_DIR)/edk2; \
	git checkout 06dc822d045; \
	git submodule update --init; \
	cd $(PWD); \
	fi
endif

# Note: BaseTools cannot be built in parallel.
basetools:
ifeq ($(SDK_VER),4.4)
	$(MAKE) -C $(UEFI_DIR)/BaseTools
else
	UEFI_DIR=${UEFI_DIR} ./buildbasetools.sh
endif

uefi $(IMG_DIR)/$(BOARD).efi.fd: basetools
	mkdir -p img
	rm -f $(IMG_DIR)/$(BOARD).efi.fd
	rm -rf $(UEFI_DIR)/Build
ifeq ($(SDK_VER),4.4)
	UEFI_DIR=$(UEFI_DIR) CROSS=$(CROSS) BUILD_TYPE=$(UEFI_BUILD_TYPE) UEFI_FLAGS="$(UEFI_FLAGS)" ./builduefi_oldsdk.sh
	cp $(UEFI_DIR)/Build/ArmBaikalBfkm-AARCH64/$(UEFI_BUILD_TYPE)_GCC6/FV/BFKM_EFI.fd $(IMG_DIR)/$(BOARD).efi.fd
else
	UEFI_DIR=$(UEFI_DIR) CROSS=$(CROSS) BUILD_TYPE=$(UEFI_BUILD_TYPE) UEFI_FLAGS="$(UEFI_FLAGS)" ./builduefi.sh
	cp $(UEFI_DIR)/Build/Baikal/$(UEFI_BUILD_TYPE)_GCC5/FV/BAIKAL_EFI.fd $(IMG_DIR)/$(BOARD).efi.fd
endif

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
ifeq ($(SDK_VER),4.4)
	$(MAKE) -C $(ARMTF_DIR) PLAT=bm1000 BE_TARGET=$(BE_TARGET) realclean
else
	$(MAKE) -C $(ARMTF_DIR) PLAT=baikal realclean
endif

.PHONY: uefi arm-tf dtb bootrom
