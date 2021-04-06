ARCH=arm64
KDIR = $(HOME)/gitlab/baikal-m/kernel
CROSS = $(HOME)/toolchains/aarch64-unknown-linux-gnueabi/bin/aarch64-unknown-linux-gnueabi-
NCPU := $(shell nproc)
B_DIR = $(CURDIR)/build
DEFCONFIG = mitx_defconfig

prepkernel: 
	mkdir -p $(B_DIR)
	$(MAKE) O=$(B_DIR) ARCH=${ARCH} CROSS_COMPILE=$(CROSS) -C $(KDIR) $(DEFCONFIG)
	$(MAKE) O=$(B_DIR) -j$(NCPU) ARCH=${ARCH} CROSS_COMPILE=$(CROSS) -C $(KDIR) 

driver: prepkernel
	$(MAKE) O=$(B_DIR) ARCH=${ARCH} CROSS_COMPILE=$(CROSS) -C $(KDIR) M=$(CURDIR)

clean:
	make O=$(B_DIR) -C $(KDIR) M=$(CURDIR) clean
