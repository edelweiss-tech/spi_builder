BEGIN {i=0};
/img[0-9]/ { i++; }
/img[0-9].*EFI System/ {
	print "sudo mount -t vfat -o loop,offset="$2/2 "K,sizelimit="$4/2"K "img" d_"i
}
/img[0-9].*Linux filesystem/ {
	print "sudo mount -t ext4 -o loop,offset="$2/2 "K,sizelimit="$4/2"K "img" d_"i
}
