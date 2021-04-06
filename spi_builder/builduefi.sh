#!/bin/bash 
export WORKSPACE= # for Jenkins' workspace to not interfere with UEFI's one
export EDK_TOOLS_PATH=${UEFI_DIR}/BaseTools
export GCC6_AARCH64_PREFIX=${CROSS}
cd ${UEFI_DIR}
. ./edksetup.sh BaseTools --reconfig || exit
build -p ArmBaikalPkg/ArmBaikalBfkm.dsc -b ${UEFI_FLAGS} || exit
echo "UEFI build: Done"
exit 0

