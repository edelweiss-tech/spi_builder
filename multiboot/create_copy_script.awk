#!/usr/bin/gawk -f
BEGIN {nl=0;
	printf("#!/bin/bash -x\n");
	printf("# Usage: my.sh /dev/sdf path_to_oses.img\n");
	printf("parted ${1} --script mklabel gpt\n");
	printf("partprobe -s ${1}\n");
	printf("sync\n");
}
/^\/dev/ {
	f=$0
	nl++
	FS=":";
	split(f,spiped);
	FS=",";
	split(spiped[2],smaller);
	start_field = smaller[1];
	sub(/start= +/,"",start_field)
	start_mb = strtonum(start_field)/2/1024;
	size_field = smaller[2];
	sub(/size= +/,"",size_field)
	size_mb = strtonum(size_field)/2/1024;
	end_mb = size_mb + start_mb;
	name_field = smaller[5];
	sub(/ name=/,"",name_field)
	gsub(/"/,"",name_field)

#	printf("%dMiB | %dMiB\n",start_mb, end_mb);
	printf("parted ${1} --script -a optimal -- mkpart primary ");
	if (1 == nl) {
		printf("fat32 %dMiB %dMiB name %d \"EFI\" set %d esp on set %d boot on\n", start_mb, end_mb, nl, nl, nl);
		printf("partprobe -s ${1}\n")
		printf("sync\n");
		printf("yes | mkfs.vfat -F 32 ${1}%d\n", nl);
		printf("sync\n");
		printf("mkdir -p d_%d\n", nl);
		printf("mount -t vfat -o loop,offset=%dM,sizelimit=%dM ${2} d_%d\n", start_mb, size_mb, nl);
		printf("mkdir -p /tmp/efi\n");
		printf("mount ${1}%d /tmp/efi\n", nl);
		printf("tar -cpf - -C ./d_%d . | tar -xpf - -C /tmp/efi\n", nl);
	} else if (4 == nl) {
		printf("linux-swap %dMiB %dMiB name %d \"%s\"\n", start_mb, end_mb, nl, name_field);
		printf("partprobe -s ${1}\n")
		printf("sync\n");
		printf("mkswap ${1}%d\n", nl);
		printf("sync\n");
	} else {
		printf("ext4 %dMiB %dMiB name %d \"%s\"\n", start_mb, end_mb, nl, name_field);
		printf("partprobe -s ${1}\n")
		printf("sync\n");
		printf("yes | mkfs.ext4 ${1}%d\n", nl);
		printf("sync\n");
		printf("mkdir -p d_%d\n", nl);
		printf("mount -t ext4 -o loop,offset=%dM,sizelimit=%dM ${2} d_%d\n", start_mb, size_mb, nl);
		printf("mkdir -p /tmp/%s\n", name_field);
		printf("mount ${1}%d /tmp/%s\n", nl, name_field);
		printf("tar --acls -cpf - --exclude='./tmp' -C ./d_%d . | tar --acls -xpf - -C /tmp/%s\n", nl, name_field);
	}
}
END {
# printf("efi_uuid=$(/usr/sbin/blkid ${TARGET_DEV}1 | cut -d" " -f2 | awk -F= '{gsub(/"/,"",$2); print $2}')"\n)

}

