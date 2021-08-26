# Install Arch Linux

### Setup live system

Keyboard layout

    loadkeys de-latin1

> List available keyboard layouts
>
>     ls /usr/share/kbd/keymaps/\*_/_.map.gz

Font

    setfont ter-128n

> List available fonts
>
>     ls /usr/share/kbd/consolefonts

Connect to WiFi

    iwctl
    station list
    station <wlan interface> connect <SSID>

Date and Time

    timedatectl set-ntp true
    timedatectl set-timezone Europe/Berlin

### BIOS or UEFI?

    ls /sys/firmware/efi/efivars

If the command shows the directory without error, then the system is booted in UEFI mode, otherwise in BIOS.

### Create partitions and mount them

    cfdisk

> Get memory info
>
>     cat /proc/meminfo

#### Without encryption

Create

    BIOS
        /dev/sda1 -> /boot, type: ext4, 512M
    UEFI
        /dev/sda1 -> /efi, type: EFI System Partition, 512M
    /dev/sda2 -> [SWAP], type: Linux Swap, Size of RAM + sqrt(Size of RAM)
    /dev/sda3 -> /mnt, type ext4, All remaining space

Format

    BIOS
        mkfs.ext4 /dev/sda1
    UEFI
        mkfs.fat -F32 /dev/sda1
    mkswap /dev/sda2
    mkfs.ext4 /dev/sda3

Mount

      mount /dev/sda3 /mnt
      BIOS
          mkdir /mnt/boot
          mount /dev/sda1 /mnt/boot
      UEFI
          mkdir /mnt/efi
          mount /dev/sda1 /mnt/efi
      swapon /dev/sda2

#### With encrypted root partition

Create

    BIOS
        /dev/sda1 -> /boot, type: ext4, 512M
        /dev/sda2 -> [SWAP], type: Linux Swap, Size of RAM + sqrt(Size of RAM)
        /dev/sda3 -> /mnt, type ext4, All remaining space
    UEFI
        /dev/sda1 -> /efi, type: EFI System Partition, 512M
        /dev/sda2 -> /boot, type: ext4, 512M
        /dev/sda3 -> [SWAP], type: Linux Swap, Size of RAM + sqrt(Size of RAM)
        /dev/sda4 -> /mnt, type ext4, All remaining space

Encrypt root partition

    BIOS
        cryptsetup -s 512 -h sha512 -y -i 5000 luksFormat /dev/sda3
    UEFI
        cryptsetup -s 512 -h sha512 -y -i 5000 luksFormat /dev/sda4

Unlock root partition

    BIOS
        cryptsetup open /dev/sda3 cryptroot
    UEFI
        cryptsetup open /dev/sda4 cryptroot

> To close it
>
>     cryptsetup close cryptroot

Format

    BIOS
        mkfs.ext4 /dev/sda1
        mkswap /dev/sda2
    UEFI
        mkfs.fat -F32 /dev/sda1
        mkfs.ext4 /dev/sda2
        mkswap /dev/sda3
    mkfs.ext4 /dev/mapper/cryptroot

Mount

    mount /dev/mapper/cryptroot /mnt
    BIOS
        mkdir /mnt/boot
        mount /dev/sda1 /mnt/boot
        swapon /dev/sda2
    UEFI
        mkdir /mnt/efi
        mount /dev/sda1 /mnt/efi
        mkdir /mnt/boot
        mount /dev/sda2 /mnt/boot
        swapon /dev/sda3

### Package Installation

    pacstrap /mnt base base-devel linux linux-firmware gvim terminus-font man-db man-pages texinfo networkmanager wpa_supplicant xorg-server xorg-apps xorg-xinit gdm gnome-control-center noto-fonts gnome-tweaks gnome-keyring gnome-terminal nautilus

### System Setup

Generate fstab

    genfstab -U /mnt >> /mnt/etc/fstab

Chroot into system

    arch-chroot /mnt

Date and Time

    ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    hwclock --systohc

Localization

    vim /etc/locale.gen
    # uncomment en_US.UTF-8 UTF-8 and other needed locales
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo "KEYMAP=de-latin1" > /etc/vconsole.conf

Network Configuration

    echo "myhostname" > /etc/hostname
    vim /etc/hosts
        127.0.0.1	localhost
        ::1		localhost
        127.0.1.1	myhostname.localdomain	myhostname

Root Password

    passwd

#### Boot Loader

##### With Encryption

Do the following after `pacman -S grub` and before `grub-install`:

Get UUID of encrypted partition

    lsblk -o +UUID

Add kernel parameter to `GRUB_CMDLINE_LINUX` in `/etc/default/grub`

    cryptdevice=UUID=<UUID of encrypted partition>:cryptroot

Add encrypt hook to `HOOKS` in `/etc/mkinitcpio.conf` (Add at the end)

    HOOKS="... encrypt"

Regenerate initramfs image (ramdisk)

    mkinitcpio -p linux

##### BIOS

    pacman -S grub
    grub-install --recheck /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg

##### UEFI

    pacman -S grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

> - Install os-prober as well if other operating systems should be auto-detected
> - If you get the following output: `Warning: os-prober will not be executed to detect other bootable partitions`:
>   - Edit `/etc/default/grub` and add/uncomment `GRUB_DISABLE_OS_PROBER=false`

##### Enable processor-specific microcode updates

Depending on the processor, install the suitable package

> Get processor info
>
>     cat /proc/cpuinfo

    AMD
        pacman -S amd-ucode
    Intel
        pacman -S intel-ucode

Recreate grub config

    grub-mkconfig -o /boot/grub/grub.cfg

### Post-Installation

Enable and start systemd services

    systemctl enable --now NetworkManager
    systemctl enable --now wpa_supplicant
    systemctl enable --now systemd-resolved
    systemctl enable --now gdm

Additional Software

    pacman -S gvim zsh tmux seafile-client xdotool gparted sshfs pwgen xclip the_silver_searcher ranger peco tig fzf lynx exa winff easytag audacity gimp vlc

asdf

    git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
    cd $HOME/.asdf
    git checkout "$(git describe --abbrev=0 --tags)"

AUR Helper

    git clone https://aur.archlinux.org/yay-git.git
    cd yay
    makepkg -si

Install Google Chrome

    yay -S google-chrome

> Upgrade:
>
>     yay -Syu

Gnome Settings

    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.shell enable-hot-corners false
    gsettings set org.gnome.shell.app-switcher current-workspace-only true

Users and Groups

    TODO

### Additional stuff

#### Add keyfile in addition to passphrase to decrypt root partition

Recommended: Format usb stick with ext4

Create key file

    dd bs=512 count=4 if=/dev/random of=/media/usbstick/mykeyfile iflag=fullblock

Deny access to others than root

    chmod 600 /media/usbstick/mykeyfile

Add a keyslot for the keyfile to the LUKS header

    cryptsetup luksAddKey /dev/sda[3/4] /media/usbstick/mykeyfile

> Manually unlocking a partition using a keyfile
>
>     cryptsetup open /dev/sda[3/4] cryptroot --key-file /media/usbstick/mykeyfile

##### Unlocking the root partition at boot

Edit `MODULES` in `/etc/mkinitcpio.conf` and add the usb stick's filesystem (e.g. ext4 or vfat)

    MODULES=(ext4)

Regenerate initramfs image (ramdisk)

    mkinitcpio -p linux

Add kernel parameter to `GRUB_CMDLINE_LINUX` in `/etc/default/grub`

    cryptkey=UUID=<UUID of usb stick partition with key file>:auto:/absolute/path/to/mykeyfile

Recreate grub config

    grub-mkconfig -o /boot/grub/grub.cfg

#### GRUB Hidden Menu

    vim /etc/default/grub
        GRUB_TIMEOUT=0
        GRUB_TIMEOUT_STYLE=hidden

Recreate grub config

    grub-mkconfig -o /boot/grub/grub.cfg

> Show GRUB menu on boot:
>
> - BIOS: Hold down Shift while GRUB is loading
> - UEFI: Press Esc several times while GRUB is loading

#### How to power off properly

One of these:

    $ systemctl poweroff
    $ halt -p
    $ shutdown -h now

#### Using iwctl instead of `networkmanager` and `wpa_supplicant`

Instead of installing `networkmanager` and `wpa_supplicant`:

    pacman -S iwd

    vim /etc/iwd/main.conf
        [General]
        EnableNetworkConfiguration=true

    systemctl enable --now iwd

### References

- https://wiki.archlinux.org/title/Installation_guide
- https://wiki.archlinux.org/title/GRUB
- https://www.arcolinuxd.com/5-the-actual-installation-of-arch-linux-phase-1-bios/
- https://averagelinuxuser.com/ubuntu-vs-arch-linux/
- https://www.howtoforge.com/tutorial/how-to-install-arch-linux-with-full-disk-encryption/
- https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Keyfiles
