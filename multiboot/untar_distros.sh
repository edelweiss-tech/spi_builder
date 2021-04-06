#!/bin/bash

# Read partition UUIDs from the new disk and update /etc/fstab for
# every distro. Also update cumulatative grub.cfg for REDOS.

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

# End of configurable parameters

echo "Untar EFI ..."
tar --acls -cpf - -C ./d_1 . | tar --acls -xpf - -C /tmp/efi
sync
echo "Untar REDOS ..."
tar --acls -cpf - --exclude='./tmp' -C ./d_2 . | tar --acls -xpf - -C /tmp/redos
sync
echo "Untar EDELW ..."
tar --acls -cpf - --exclude='./tmp' -C ./d_3 . | tar --acls -xpf - -C /tmp/edelsw
sync
echo "Untar ALT ..."
tar --acls -cpf - --exclude='./tmp' -C ./d_5 . | tar --acls -xpf - -C /tmp/alt
sync
echo "Untar ASTRA ..."
tar --acls -cpf - --exclude='./tmp' -C ./d_6 . | tar --acls -xpf - -C /tmp/astra
sync
echo "Untar WAYLAND ..."
tar --acls -cpf - --exclude='./tmp' -C ./d_7 . | tar --acls -xpf - -C /tmp/wayland
sync
echo "Untar Ubuntu ..."
tar --acls -cpf - --exclude='./tmp' -C ./d_8 . | tar --acls -xpf - -C /tmp/ubuntu
sync

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

sed -e 's/EFI_STUB/'${efi_uuid}'/; s/SWAP_STUB/'${swap_uuid}'/;
s/WAYLAND_STUB/'${wayland_uuid}'/;' fstab.wayland.template >  /tmp/wayland/etc/fstab

sed -e 's/EFI_STUB/'${efi_uuid}'/;
s/UBUNTU_STUB/'${ubuntu_uuid}'/;' fstab.ubuntu.template >  /tmp/ubuntu/etc/fstab


sed -e 's/REDOS_STUB/'${redos_uuid}'/; s/EDELW_STUB/'${edelsw_uuid}'/;
s/ALT_STUB/'${alt_uuid}'/; s/ASTRA_STUB/'${astra_uuid}'/;
s/WAYLAND_STUB/'${wayland_uuid}'/; 
s/UBUNTU_STUB/'${ubuntu_uuid}'/;' grub.template > /tmp/edelsw/boot/grub/grub.cfg

sed -e 's/EDELW_STUB/'${edelsw_uuid}'/;' efi_grub.template > /tmp/efi/EFI/debian/grub.cfg
sed -e 's/EDELW_STUB/'${edelsw_uuid}'/;' startup.nsh.template > /tmp/efi/startup.nsh

