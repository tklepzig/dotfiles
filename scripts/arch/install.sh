pacstrap /mnt base base-devel linux linux-firmware vim iwd terminus-font man-db man-pages texinfo networkmanager
genfstab -U /mnt >> /mnt/etc/fstab
