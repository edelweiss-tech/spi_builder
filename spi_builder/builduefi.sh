#!/bin/bash 

if [ -z "${UEFI_DIR}" ] ; then
	echo "UEFI_DIR must be set!"
	exit
fi

NPROC=`nproc`
if [ $NPROC -gt 1 ] ; then
	NPROC=`expr $NPROC - 1`
fi

if [ "${SDK_VER}" = "4.4" ]; then
	export WORKSPACE= # for Jenkins' workspace to not interfere with UEFI's one
	export EDK_TOOLS_PATH=${UEFI_DIR}/edk2/BaseTools
	export GCC6_AARCH64_PREFIX=${CROSS}
	cd ${UEFI_DIR}/edk2
	if ! [ -f ./Conf/target.txt ] ; then
		mkdir -p ${UEFI_DIR}/edk2/Conf
		. ./edksetup.sh --reconfig || exit
	else
		. ./edksetup.sh || exit
	fi
	build -p ArmBaikalPkg/ArmBaikalBfkm.dsc -b ${BUILD_TYPE} ${UEFI_FLAGS} || exit
else
	export WORKSPACE=${UEFI_DIR}
	export EDK_TOOLS_PATH=${UEFI_DIR}/edk2/BaseTools
	export GCC5_AARCH64_PREFIX=${CROSS}
	export ARCH=AARCH64
	export PACKAGES_PATH=${WORKSPACE}/edk2:${WORKSPACE}/edk2-non-osi:${WORKSPACE}/edk2-platform-baikal
	cd ${UEFI_DIR}
	if ! [ -f edk2/Conf/target.txt ] ; then
		. edk2/edksetup.sh --reconfig || exit
	else
		. edk2/edksetup.sh || exit
	fi
	echo "Running build -p Platform/Baikal/Baikal.dsc -b ${BUILD_TYPE} -a ${ARCH} -t GCC5 -n ${NPROC} ${UEFI_FLAGS}"
	build -p Platform/Baikal/Baikal.dsc -b ${BUILD_TYPE} -a ${ARCH} -t GCC5 -n ${NPROC} ${UEFI_FLAGS} || exit
fi
echo "UEFI build: Done"
exit 0
