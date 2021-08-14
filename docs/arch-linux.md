# 1. Setup live system

    setfont ter-128n

> List available fonts: `ls /usr/share/kbd/consolefonts`

    loadkeys de-latin1

> List available keyboard layouts: `ls /usr/share/kbd/keymaps/\*_/_.map.gz`

    iwctl
    station wlan0 ...

    todo

# 2. Install linux and additional packages

    pacstrap /mnt base base-devel linux linux-firmware vim iwd terminus-font man-db man-pages texinfo networkmanager

## 2a. Encryption

    todo

# 3. Setup system while chrooted

    arch-chroot /mnt
    todo

## 3a. BIOS

    pacman -S grub
    grub-install --recheck /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg

## 3b. UEFI

Ensure the EFI system partition is mounted (`/efi`)

    pacman -S grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

# 4. Reboot

# 5. Post-Installation

    pacman -S xorg-server xorg-apps xorg-xinit gdm gnome-control-center noto-fonts

> Also `network-manager-applet`?

    systemctl enable gdm
    systemctl enable NetworkManager
    systemctl enable iwd
    systemctl enable systemd-resolved

    systemctl start gdm

---

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

~~Edit /etc/resolv.conf and use content from another working linux (?? --> improve this tip)~~

pacman -S xorg-server xorg-apps xorg-xinit gdm gnome-control-center network-manager-applet
systemctl enable gdm
systemctl start gdm

~~pacman -S ttf-ubuntu-font-family~~
pacman -S noto-fonts

i3wm i3status (dmenu | dmenu-xft)

ToDo
gnome tweak tools
~~Resolution during installation: Add this parameter to kernel line on boot screen (press <kbd>e</kbd>): `nomodeset video=2048x1152`~~

# GRUB Hidden Menu

Edit /etc/default/grub:

    GRUB_TIMEOUT=0
    GRUB_TIMEOUT_STYLE='hidden'

Recreate grub config:

    grub-mkconfig -o /boot/grub/grub.cfg

# UEFI

- Ensure we're chrooted into the system
- Ensure the EFI system partition is mounted (`/efi`)
- `pacman -S grub efibootmgr`
- `grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB`
- `grub-mkconfig -o /boot/grub/grub.cfg`

# Encrypted

- Create partitions: `cfdisk`
- Encrypt root partition: `cryptsetup -s 512 -h sha512 -y -i 5000 luksFormat /dev/sda2`
- Unlock partition: `cryptsetup open /dev/sda2 cryptroot`
  > To close it: `cryptsetup close cryptroot`
- Format partitions:
  - `mkfs.ext4 /dev/sda1`
  - `mkfs.ext4 /dev/mapper/cryptroot`
- Mount the partitions:
  - `mount /dev/mapper/cryptroot /mnt`
  - `mkdir /mnt/boot`
  - `mount /dev/sda1 /mnt/boot`
- Install packages: pacstrap /mnt ...
- Generate fstab, chroot, locales, ...
- Install grub: `pacman -S grub`
  > - Install os-prober as well if other operating systems should be auto-detected
  > - If you get the following output: `Warning: os-prober will not be executed to detect other bootable partitions`:
  >   - Edit `/etc/default/grub` and add/uncomment `GRUB_DISABLE_OS_PROBER=false`
- Get UUID of encrypted partition: `lsblk --output +UUID`
- Add kernel parameter to `GRUB_CMDLINE_LINUX` in `/etc/default/grub`: `cryptdevice=UUID={UUID of encrypted partition}:cryptroot`
- Add encrypt hook to `HOOKS` in `/etc/mkinitcpio.conf` (Add at the end): `HOOKS="... encrypt"`
- Regenerate initramfs image (ramdisk): `mkinitcpio -p linux`
- Install grub: `grub-install --recheck /dev/sda`
- Save its config file: `grub-mkconfig -o /boot/grub/grub.cfg`
- Reboot

## Use keyfile in addition to passphrase

- Recommended: Format usb stick with ext4
- Create key file: `dd bs=512 count=4 if=/dev/random of=/media/usbstick/mykeyfile iflag=fullblock`
- Deny access to others than root: `chmod 600 /etc/mykeyfile`
- Add a keyslot for the keyfile to the LUKS header: `cryptsetup luksAddKey /dev/sda2 /media/usbstick/mykeyfile`
  > Manually unlocking a partition using a keyfile: `cryptsetup open /dev/sda2 cryptroot --key-file /media/usbstick/mykeyfile`
- Unlocking the root partition at boot
  - Edit `MODULES` in `/etc/mkinitcpio.conf` and add the usb stick's filesystem (e.g. ext4 or vfat): `MODULES=(ext4)`
  - Regenerate initramfs image (ramdisk): `mkinitcpio -p linux`
  - Add kernel parameter to `GRUB_CMDLINE_LINUX` in `/etc/default/grub`: `cryptkey=UUID={UUID of usb stick partition with key file}:auto:/absolute/path/to/mykeyfile`
  - Update grub config file: `grub-mkconfig -o /boot/grub/grub.cfg`
- See also https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Keyfiles

# See also

- https://wiki.archlinux.org/title/Installation_guide
- https://wiki.archlinux.org/title/GRUB
- https://www.arcolinuxd.com/5-the-actual-installation-of-arch-linux-phase-1-bios/
- https://averagelinuxuser.com/ubuntu-vs-arch-linux/
- https://www.howtoforge.com/tutorial/how-to-install-arch-linux-with-full-disk-encryption/
