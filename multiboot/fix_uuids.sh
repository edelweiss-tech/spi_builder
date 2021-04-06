#!/bin/bash

help()
{
	echo "Usage: $0 <dev>"
	exit 1
}

if [ $# -ne 1 ]; then
  help
fi
# Choose which newly partitioned disk to work on
TARGET_DEV="$1"

efi_uuid=$(/usr/sbin/blkid ${TARGET_DEV}1 | sed 's/.* UUID="\([^"]*\).*$/\1/')
redos_uuid=$(/usr/sbin/blkid ${TARGET_DEV}2 | sed 's/.* UUID="\([^"]*\).*$/\1/')
edelsw_uuid=$(/usr/sbin/blkid ${TARGET_DEV}3 | sed 's/.* UUID="\([^"]*\).*$/\1/')
swap_uuid=$(/usr/sbin/blkid ${TARGET_DEV}4 | sed 's/.* UUID="\([^"]*\).*$/\1/')
alt_uuid=$(/usr/sbin/blkid ${TARGET_DEV}5 | sed 's/.* UUID="\([^"]*\).*$/\1/')
astra_uuid=$(/usr/sbin/blkid ${TARGET_DEV}6 | sed 's/.* UUID="\([^"]*\).*$/\1/')
wayland_uuid=$(/usr/sbin/blkid ${TARGET_DEV}7 | sed 's/.* UUID="\([^"]*\).*$/\1/')
ubuntu_uuid=$(/usr/sbin/blkid ${TARGET_DEV}8 | sed 's/.* UUID="\([^"]*\).*$/\1/')

# Edit /etc/fstab files
sed -e 's/EFI_STUB/'${efi_uuid}'/; s/SWAP_STUB/'${swap_uuid}'/;
s/REDOS_STUB/'${redos_uuid}'/;' fstab.redos.template > /tmp/redos/etc/fstab

sed -e 's/EFI_STUB/'${efi_uuid}'/; s/SWAP_STUB/'${swap_uuid}'/; 
s/EDELW_STUB/'${edelsw_uuid}'/;' fstab.edelsw.template >  /tmp/edelsw/etc/fstab

sed -e 's/EFI_STUB/'${efi_uuid}'/; s/SWAP_STUB/'${swap_uuid}'/;
s/ALT_STUB/'${alt_uuid}'/;' fstab.alt.template >  /tmp/alt/etc/fstab

sed -e 's/EFI_STUB/'${efi_uuid}'/; s/SWAP_STUB/'${swap_uuid}'/;
s/ASTRA_STUB/'${astra_uuid}'/;' fstab.astra.template >  /tmp/astra/etc/fstab

sed -e 's/REDOS_STUB/'${redos_uuid}'/; s/EDELW_STUB/'${edelsw_uuid}'/;
s/ALT_STUB/'${alt_uuid}'/; s/ASTRA_STUB/'${astra_uuid}'/;' grub.template > /tmp/edelsw/boot/grub/grub.cfg

sed -e 's/EDELW_STUB/'${edelsw_uuid}'/;' efi_grub.template > /tmp/efi/EFI/debian/grub.cfg
sed -e 's/EDELW_STUB/'${edelsw_uuid}'/;' startup.nsh.template > /tmp/efi/startup.nsh
