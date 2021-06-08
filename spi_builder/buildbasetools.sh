#!/bin/bash

cd ${UEFI_DIR}

if [ "${SDK_VER}" = "4.4" ]; then
	:
else
	export WORKSPACE=`pwd`
	export EDK_TOOLS_PATH=${WORKSPACE}/edk2/BaseTools
	export PACKAGES_PATH=${WORKSPACE}/edk2:${WORKSPACE}/edk2-non-osi:${WORKSPACE}/edk2-platform-baikal
	. edk2/edksetup.sh || exit
fi
make -C edk2/BaseTools
