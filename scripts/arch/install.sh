if [ -z $1 ] || [ -z $2 ]
then
	echo "Usage: install.sh boot-partition root-partition"
	echo "e.g. install.sh /dev/sda1 /dev/sda2"
exit 1
fi

mkdir /mnt/boot
mount $2 /mnt
mount $1 /mnt/boot
pacstrap /mnt base linux linux-firmware vim iwd terminus-font man-db man-pages texinfo networkmanager
genfstab -U /mnt >> /mnt/etc/fstab
