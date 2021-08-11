if [ -z $1 ]
then
	echo "Usage: after-chroot.sh /dev/sdx"
	exit
fi

ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
echo "Setting root password..."
passwd
echo "Done"
pacman -S grub
grub-install --target=i386-pc $1
grub-mkconfig -o /boot/grub/grub.cfg

echo "Now setup:"
echo "- Localization"
echo "- Hostname and network config"
echo "- Reboot"
