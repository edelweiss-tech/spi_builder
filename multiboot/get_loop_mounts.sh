#!/bin/bash
# provide path to image allos.img as argument 1
# skip swap partition

help()
{
	echo "Usage: $0 <file.img>"
	exit 1
}

MNTSCRT="/tmp/tomount.sh"
if [ $# -ne 1 ]; then
  help
fi

# Skip 4 as it is a swap partion
mkdir -p d_{1,2,3,5,6,7,8}
echo "#!/bin/bash" > ${MNTSCRT}
/usr/sbin/sfdisk -l $1 | awk -v img=$1 -f ./parse_sfdisk.awk >> ${MNTSCRT}
echo "df -h | grep loop." >> ${MNTSCRT}
chmod u+x ${MNTSCRT}
echo 
echo "Done! The mount script is ${MNTSCRT}"

