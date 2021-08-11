# Adjust font

    ls /usr/share/kbd/consolefonts
    setfont ter-128n

# Set keyboard layout

    ls /usr/share/kbd/keymaps/\*_/_.map.gz
    loadkeys de-latin1

# Network

    iwctl
    station wlan0 ...

# Installation

    pacstrap /mnt base linux linux-firmware vim iwd terminus-font man-db man-pages texinfo networkmanager

# GRUB Bootloader

After chroot:

    pacman -S grub
    grub-install --target=i386-pc /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg

# Power off

One of these:

    $ systemctl poweroff
    $ halt -p
    $ shutdown -h now

systemctl enable NetworkManager
systemctl enable iwd
systemctl enable systemd-resolved

_Maybe:_ edit /etc/resolv.conf and use content from another working linux (?? --> improve this tip)

pacman -S xorg-server xorg-apps xorg-xinit gdm gnome-control-center network-manager-applet
systemctl enable gdm
systemctl start gdm

_Maybe:_ pacman -S ttf-ubuntu-font-family
pacman -S noto-fonts

i3wm i3status (dmenu | dmenu-xft)

ToDo
Encrypt hdd (LUKS)
gnome tweak tools
_Seems not to work:_ Resolution during installation: Add this parameter to kernel line on boot screen (press <kbd>e</kbd>): `nomodeset video=2048x1152`

# See also

- https://wiki.archlinux.org/title/Installation_guide
- https://wiki.archlinux.org/title/GRUB
- https://www.arcolinuxd.com/5-the-actual-installation-of-arch-linux-phase-1-bios/
- https://averagelinuxuser.com/ubuntu-vs-arch-linux/
