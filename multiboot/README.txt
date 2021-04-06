New way:

Save the image with the partition table stored separately:

sudo dd if=/dev/sdf of=fouros.img bs=1M conv=sync,noerror status=progress
sudo sfdisk --dump /dev/sdf > pt.dump

Copy the created image from file, not duplicating the UUIDs.

./create_copy_script.awk ~/d1/diskimages/20210401/pt.dump > /tmp/my.sh 
sudo /tmp/my.sh /dev/sdf ~/d1/diskimages/20210401/fouros.img 
sudo ./fix_uuids.sh /dev/sdf
sudo umount /dev/loop?
sudo umount /dev/sdf?


Old way:
These are the steps to prepare the new demo disk with multiple distros.

1. Connect an empty disk and create partitions:

$ sudo ./create_partitions.sh /dev/sdf

2. List suggested loop mounts for the source disk image:

$ ./get_loop_mounts.sh <file.img>

Mount the suggested "loops" from /tmp/tomount.sh
$ sudo /tmp/tomount.sh

3. Untar the distro from the "loops", update UUIDs in /etc/fstab
and grub.cfg:

$ sudo ./untar_distros.sh /dev/sdf

