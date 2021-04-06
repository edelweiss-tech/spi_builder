BEGIN {i=0};
/img[0-9]/ { i++; }
/img[0-9].*EFI System/ {
	printf "mount -t vfat -o loop,offset=%dK,sizelimit=%dK %s d_%d\n", $2/2, $4/2, img, i
}
/img[0-9].*Linux filesystem/ {
	printf "mount -t ext4 -o loop,offset=%dK,sizelimit=%dK %s d_%d\n", $2/2, $4/2, img, i
}

#$ sudo sfdisk -l /dev/sdf
#Disk /dev/sdf: 111.8 GiB, 120034123776 bytes, 234441648 sectors
#Disk model: SX100 120GB
#Units: sectors of 1 * 512 = 512 bytes
#Sector size (logical/physical): 512 bytes / 512 bytes
#I/O size (minimum/optimal): 512 bytes / 512 bytes
#Disklabel type: gpt
#Disk identifier: 23F51085-3E55-47E7-B95B-25BBBF78BD33
#
#Device         Start       End  Sectors  Size Type
#/dev/sdf1       2048    526335   524288  256M EFI System
#/dev/sdf2     526336  60430335 59904000 28.6G Linux filesystem
#/dev/sdf3   60430336 119822335 59392000 28.3G Linux filesystem
#/dev/sdf4  119822336 128014335  8192000  3.9G Linux swap
#/dev/sdf5  128014336 181258239 53243904 25.4G Linux filesystem
#/dev/sdf6  181258240 231636991 50378752   24G Linux filesystem
