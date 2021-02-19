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

