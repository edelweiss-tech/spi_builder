#!/bin/bash

# Partition and create file systems on the new disk

# Use MiB boundaries to get the correct partition alignment.
# Escape spaces in names to protect them from the shell.

help()
{
	echo "Usage: $0 <dev>"
	exit 1
}

if [ $# -ne 1 ]; then
  help
fi
TARGET_DEV="$1"

# End of configurable parameters
umount -q ${TARGET_DEV}{1,2,3,5,6,7}
echo "Running parted ..."
parted ${TARGET_DEV} --script mklabel gpt
partprobe -s ${TARGET_DEV}

parted ${TARGET_DEV} --script -a optimal -- mkpart primary fat32 1MiB 257MiB \
name 1 \"EFI\ System\" set 1 esp on set 1 boot on
partprobe -s ${TARGET_DEV}

parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 257MiB 17000MiB \
name 2 "redos"
partprobe -s ${TARGET_DEV}

parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 17000MiB 33996MiB \
name 3 "edelsw"
partprobe -s ${TARGET_DEV}

parted ${TARGET_DEV} --script -a optimal -- mkpart primary linux-swap 33996MiB 41574MiB \
name 4 "swap"
partprobe -s ${TARGET_DEV}

parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 41574MiB 61542MiB \
name 5 "alt"
partprobe -s ${TARGET_DEV}

parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 61542MiB 86118MiB \
name 6 "astra"
partprobe -s ${TARGET_DEV}

# reserve space for superblock at the end
parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 86118MiB -2048s \
name 7 "wayland"
/usr/sbin/partprobe -s ${TARGET_DEV}

echo "Creating file systems ..."
sync
yes | mkfs.vfat -F 32 ${TARGET_DEV}1
sync
yes | mkfs.ext4 ${TARGET_DEV}2
sync
yes | mkfs.ext4 ${TARGET_DEV}3
sync
mkswap ${TARGET_DEV}4
yes | mkfs.ext4 ${TARGET_DEV}5
sync
yes | mkfs.ext4 ${TARGET_DEV}6
sync
yes | mkfs.ext4 ${TARGET_DEV}7
sync
echo "Done."
