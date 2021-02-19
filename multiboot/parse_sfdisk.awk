BEGIN {i=0};
/img[0-9]/ { i++; }
/img[0-9].*EFI System/ {
	printf "mount -t vfat -o loop,offset=%dK,sizelimit=%dK %s d_%d\n", $2/2, $4/2, img, i
}
/img[0-9].*Linux filesystem/ {
	printf "mount -t ext4 -o loop,offset=%dK,sizelimit=%dK %s d_%d\n", $2/2, $4/2, img, i
}
