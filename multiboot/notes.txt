These are the steps to prepare the new demo disk with multiple distros.

1. Create partitions:

$ sudo create_partitions.sh /dev/sdf

2. List suggested loop mounts for the source disk:

$ get_loop_mounts.sh <file.img>

Mount the suggested "loops" from /tmp/tomount.sh
$ sh /tmp/tomount.sh

3. Untar the distro from the "loops", update UUIDs in /etc/fstab
and grub.cfg:

$ sudo untar_distros.sh /dev/sdf

