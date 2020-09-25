#!/bin/bash

# Partition and create file systems on the new disk

# Use MiB boundaries to get the correct partition alignment.
# Escape spaces in names to protect them from the shell.

TARGET_DEV="sde"

# End of configurable parameters
umount /dev/${TARGET_DEV}{1,2,3,5,6,7}
echo "Running parted ..."
parted /dev/${TARGET_DEV} --script mklabel gpt \
mkpart primary fat32 1MiB 257MiB \
name 1 \"EFI\ System\" \
set 1 esp on \
set 1 boot on \
mkpart primary ext4 257MiB 16998MiB \
name 2 "redos" \
mkpart primary ext4 16998MiB 33996MiB \
name 3 "edelsw" \
mkpart primary linux-swap 33996MiB 41574MiB \
name 4 "swap" \
mkpart primary ext4 41574MiB 61542MiB \
name 5 "alt" \
mkpart primary ext4 61542MiB 86118MiB \
name 6 "astra" \
mkpart primary ext4 86118MiB 113664MiB \
name 7 "wayland"

/usr/sbin/partprobe -s /dev/${TARGET_DEV}

echo "Creating file systems ..."
yes | mkfs.vfat /dev/${TARGET_DEV}1
yes | mkfs.ext4 /dev/${TARGET_DEV}2
yes | mkfs.ext4 /dev/${TARGET_DEV}3
mkswap /dev/${TARGET_DEV}4
yes | mkfs.ext4 /dev/${TARGET_DEV}5
yes | mkfs.ext4 /dev/${TARGET_DEV}6
yes | mkfs.ext4 /dev/${TARGET_DEV}7
echo "Done."
