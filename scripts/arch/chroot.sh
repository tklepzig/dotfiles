ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
echo "Setting root password..."
passwd
echo "Done"

echo "Now setup:"
echo "- Localization"
echo "- Hostname and network config"
echo "- Reboot"
