# Install Arch Linux

<!-- vim-markdown-toc GFM -->

* [Remarks before beginning](#remarks-before-beginning)
* [Setup live system](#setup-live-system)
* [BIOS or UEFI?](#bios-or-uefi)
* [Create partitions and mount them](#create-partitions-and-mount-them)
    * [Without encryption](#without-encryption)
    * [With encrypted root partition](#with-encrypted-root-partition)
* [Package Installation](#package-installation)
* [System Setup](#system-setup)
    * [Boot Loader](#boot-loader)
        * [With Encryption](#with-encryption)
        * [BIOS](#bios)
        * [UEFI](#uefi)
        * [Enable processor-specific microcode updates](#enable-processor-specific-microcode-updates)
* [Post-Installation](#post-installation)
* [Additional stuff](#additional-stuff)
    * [Add keyfile in addition to passphrase to decrypt root partition](#add-keyfile-in-addition-to-passphrase-to-decrypt-root-partition)
        * [Unlocking the root partition at boot](#unlocking-the-root-partition-at-boot)
    * [GRUB Hidden Menu](#grub-hidden-menu)
    * [How to power off properly](#how-to-power-off-properly)
    * [Using iwctl instead of `networkmanager` and `wpa_supplicant`](#using-iwctl-instead-of-networkmanager-and-wpa_supplicant)
    * [Boot into BIOS/UEFI](#boot-into-biosuefi)
    * [Systemd Timers](#systemd-timers)
    * [Disable Beep](#disable-beep)
    * [Prevent going to sleep while running a program](#prevent-going-to-sleep-while-running-a-program)
* [Upgrade System](#upgrade-system)
    * [Troubleshooting](#troubleshooting)
        * [Read the news](#read-the-news)
        * [Packages return 404 ("failed retrieving file ... The requested URL returned error: 404") from mirrors](#packages-return-404-failed-retrieving-file--the-requested-url-returned-error-404-from-mirrors)
        * [File /var/cache/pacman/pkg/something.tar.xz is corrupted (invalid or corrupted package (PGP signature)).](#file-varcachepacmanpkgsomethingtarxz-is-corrupted-invalid-or-corrupted-package-pgp-signature)
        * [Restore all packages to a specific date](#restore-all-packages-to-a-specific-date)
        * [Missing terminal glyphs / icons after upgrade (kitty shows boxes)](#missing-terminal-glyphs--icons-after-upgrade-kitty-shows-boxes)
* [Printing and Scanning (HP Officejet 4630)](#printing-and-scanning-hp-officejet-4630)
    * [Packages](#packages)
    * [Enable mDNS discovery](#enable-mdns-discovery)
    * [Configure the printer](#configure-the-printer)
    * [Print a test page](#print-a-test-page)
    * [Configure the scanner](#configure-the-scanner)
    * [Gotchas](#gotchas)
* [Bluetooth Troubleshooting](#bluetooth-troubleshooting)
* [TODO (WIP)](#todo-wip)
* [References](#references)

<!-- vim-markdown-toc -->

## Remarks before beginning

- Think about using lightdm instead of gdm (i3 compatibility, less resource
  usage)
  - Install `lightdm` and `lightdm-gtk-greeter` instead of gdm packages
  - Enable `lightdm` service instead of gdm

## Setup live system

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

## BIOS or UEFI?

    ls /sys/firmware/efi/efivars

If the command shows the directory without error, then the system is booted in
UEFI mode, otherwise in BIOS.

## Create partitions and mount them

    cfdisk

> Get memory info
>
>     cat /proc/meminfo

### Without encryption

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

### With encrypted root partition

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

## Package Installation

    pacstrap /mnt base base-devel linux linux-firmware ntfs-3g kitty git gvim zsh tmux terminus-font man-db man-pages texinfo networkmanager wpa_supplicant xorg-server xorg-xinit gdm gnome-control-center noto-fonts gnome-keyring

## System Setup

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
    localectl set-x11-keymap de

Network Configuration

    echo "myhostname" > /etc/hostname
    vim /etc/hosts
        127.0.0.1	localhost
        ::1		localhost
        127.0.1.1	myhostname.localdomain	myhostname

Root Password

    passwd

### Boot Loader

#### With Encryption

Do the following after `pacman -S grub` and before `grub-install`:

Get UUID of encrypted partition

    lsblk -o +UUID

Add kernel parameter to `GRUB_CMDLINE_LINUX` in `/etc/default/grub`

    cryptdevice=UUID=<UUID of encrypted partition>:cryptroot

Add `keyboard`, `keymap` and `encrypt` hooks to `HOOKS` in
`/etc/mkinitcpio.conf` (Add at the end)

    HOOKS=(... keyboard keymap encrypt)

> The `keyboard` hook must occur **before** `keymap`, and `keymap` must occur
> **before** the `encrypt` hook. `keyboard` is necessary for keyboard input to
> work at all in the initramfs; `keymap` is necessary to allow non-US keyboard
> layout, otherwise using a non-US keyboard for entering the passphrase could be
> a challenge...

Regenerate initramfs image (ramdisk)

    mkinitcpio -P

#### BIOS

    pacman -S grub
    grub-install --recheck /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg

#### UEFI

    pacman -S grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

> - Install os-prober as well if other operating systems should be auto-detected
> - If you get the following output:
>   `Warning: os-prober will not be executed to detect other bootable partitions`:
>   - Edit `/etc/default/grub` and add/uncomment `GRUB_DISABLE_OS_PROBER=false`

#### Enable processor-specific microcode updates

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

## Post-Installation

Enable and start systemd services

    systemctl enable --now NetworkManager
    systemctl enable --now wpa_supplicant
    systemctl enable --now systemd-resolved
    systemctl enable gdm

Add non-privileged user

    useradd -m -s /usr/bin/zsh <username>
    passwd <username>

Add user to sudoers file

    visudo
        <username>   ALL=(ALL) ALL

Start Gnome

    systemctl start gdm

Setup WiFi, Keyboard Layout, etc.

Additional Software (run as non-privileged user)

    sudo pacman -S xclip ripgrep ranger tig fzf lynx xdotool eza peco sshfs pwgen mat2 btop net-tools lsof iproute2
    sudo pacman -S nautilus gparted eog gnome-tweaks texlive-core texlive-latexextra texlive-binextra evince xpdf texworks pass paperkey
    sudo pacman -S easytag audacity gimp vlc pqiv git-delta jless git-filter-repo ueberzugpp cmus mpv mpv-mpris playerctl obs-studio
    sudo pacman -S networkmanager-vpnc android-tools smartmontools
    sudo pacman -S docker docker-buildx

Enable Docker and add user to docker group

    sudo systemctl enable --now docker.socket
    sudo usermod -aG docker $USER

> Log out and back in for the group change to take effect

    sudo pacman -S ttf-jetbrains-mono
    sudo pacman -S ncdu dysk
    # Or manually: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"

AUR Packages

    google-chrome
    seafile-client
    winff
    gdmap

Prerequisites

    pacman -S base-devel

For each desired aur package, run

    git clone https://aur.archlinux.org/package_name.git
    cd package_name
    makepkg -sic
    git clean -dfx

> For updating AUR packages, do a `git pull` and then the commands as above  
> See also https://wiki.archlinux.org/title/Arch_User_Repository

Gnome Settings

    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.interface enable-hot-corners false
    gsettings set org.gnome.shell.app-switcher current-workspace-only true

## Additional stuff

### Add keyfile in addition to passphrase to decrypt root partition

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

#### Unlocking the root partition at boot

Edit `MODULES` in `/etc/mkinitcpio.conf` and add the usb stick's filesystem
(e.g. ext4 or vfat)

    MODULES=(ext4)

Regenerate initramfs image (ramdisk)

    mkinitcpio -P

Add kernel parameter to `GRUB_CMDLINE_LINUX` in `/etc/default/grub`

    cryptkey=UUID=<UUID of usb stick partition with key file>:ext4:/absolute/path/to/mykeyfile

Recreate grub config

    grub-mkconfig -o /boot/grub/grub.cfg

### GRUB Hidden Menu

    vim /etc/default/grub
        GRUB_TIMEOUT=0
        GRUB_TIMEOUT_STYLE=hidden

Recreate grub config

    grub-mkconfig -o /boot/grub/grub.cfg

> Show GRUB menu on boot:
>
> - BIOS: Hold down Shift while GRUB is loading
> - UEFI: Press Esc several times while GRUB is loading

### How to power off properly

One of these:

    $ systemctl poweroff
    $ halt -p
    $ shutdown -h now

### Using iwctl instead of `networkmanager` and `wpa_supplicant`

Instead of installing `networkmanager` and `wpa_supplicant`:

    pacman -S iwd

    vim /etc/iwd/main.conf
        [General]
        EnableNetworkConfiguration=true

    systemctl enable --now iwd

### Boot into BIOS/UEFI

    systemctl reboot --firmware-setup

### Systemd Timers

    TODO

> https://wiki.archlinux.de/title/Systemd/Timers

### Disable Beep

Create file `/etc/modprobe.d/nobeep.conf` with the following content:

    blacklist pcspkr
    blacklist snd_pcsp

> See https://wiki.archlinux.org/title/PC_speaker#Disable_PC_Speaker

### Prevent going to sleep while running a program

Useful e.g. when playing audio/video and avoid going to suspend while playing

    gnome-session-inhibit --inhibit suspend /path/to/program

> e.g. for VLC
>
>     gnome-session-inhibit --inhibit suspend vlc

or only inhibit, without starting a program

    gnome-session-inhibit --inhibit suspend --inhibit-only

## Upgrade System

First, upgrade arch and all packages

    sudo pacman -Syu

> If the mirror list is out of date, you can force the refesh of the db by using
> two y's, so -Syy  
> From time to time, the mirrors list itself should be updated, see
> https://archlinux.org/mirrorlist/

Afterwards, upgrade the AUR packages by doing a `git pull` and `makepkg -si` in
the respective repositories.

### Troubleshooting

#### Read the news

Checkout https://archlinux.org/news/ for any solutions to known issues.

#### Packages return 404 ("failed retrieving file ... The requested URL returned error: 404") from mirrors

Your sync db is stale: it references package versions the mirrors have already
replaced with newer builds, so the old files are gone. Almost always caused by a
partial upgrade (installing with `pacman -S <pkg>` or `-Sy <pkg>` against an
out-of-date db instead of `-Syu`). Often shows up together with "invalid
signature" errors (see below). Recover with a full upgrade, refreshing the
keyring first:

    sudo pacman -Sy archlinux-keyring && sudo pacman -Su

> `-Sy archlinux-keyring` refreshes the db and updates the signing keyring (it's
> signed by Arch master keys already trusted on your system, so it verifies even
> when other packages don't). `-Su` then upgrades everything against the fresh
> db. After this, install the package you originally wanted with `-Syu <pkg>`.

#### File /var/cache/pacman/pkg/something.tar.xz is corrupted (invalid or corrupted package (PGP signature)).

That means that the package integrity cannot be checked by its PGP signature.
Often the reason is that you may have done the previous update a while ago. In
the meantime some keys by Arch developers may have changed, and some new updates
are signed with the new (PGP) keys.

Update the keyring

    sudo pacman -Sy archlinux-keyring

#### Restore all packages to a specific date

Edit `/etc/pacman.conf` and replace the `Include` for the desired mirrors (e.g.
`core`, `extra` and `multilib`) with a specific `Server` (best by commenting out
`Include`) which contains the desired date, see below:

    [core]
    #Include = /etc/pacman.d/mirrorlist
    # Using package versions as of 2025-07-20
    Server = https://archive.archlinux.org/repos/2025/07/20/$repo/os/$arch

Then update the package database and force a downgrade:

    pacman -Syyuu

> See also
> https://wiki.archlinux.org/title/Arch_Linux_Archive#How_to_restore_all_packages_to_a_specific_date

#### Missing terminal glyphs / icons after upgrade (kitty shows boxes)

After a `-Syu` that bumps `fontconfig` (e.g. `2.17 → 2.18`, which changes the
cache format), the per-user font cache can go stale. kitty then resolves glyphs
against bad data and routes symbols — e.g. play `⏵` / pause `⏸` in the tmux
statusline — to a font that can't render them, so they show as tofu boxes.

Rebuild the font cache and restart kitty (close **all** windows — fallback is
resolved at startup):

    fc-cache -rf            # -r wipes stale cache dirs, -f forces a full rebuild

Verify a symbol now resolves to a real font and not a stray `.woff2` web font:

    for cp in 23F5 23F8 23EF; do printf "U+%s -> " "$cp"; fc-match ":charset=$cp"; done

> `kitty/kitty.linux.conf` also pins the media-control block (`U+23E9–U+23FA`)
> to _Noto Sans Symbols 2_ via `symbol_map`, making fallback deterministic. But
> `fc-cache -rf` is the real safeguard, since `symbol_map` still resolves the
> pinned family through fontconfig.

## Printing and Scanning (HP Officejet 4630)

Network all-in-one (print + scan) on the LAN. Setup that actually works on Arch:
**hpcups** for printing, **sane-airscan** (driverless eSCL) for scanning. Do
_not_ rely on HPLIP's `hpaio` or sane's built-in `escl` backend for scanning —
both are broken for this model (see [Gotchas](#gotchas)).

First find the printer's IP (from its own panel under Settings → Network, or via
the router). Examples below use `192.168.178.58`.

### Packages

    sudo pacman -Syu hplip sane sane-airscan simple-scan nss-mdns

> - `hplip` — print driver (hpcups) + `hp-setup`
> - `sane` + `sane-airscan` — scanning framework + the driverless eSCL backend
> - `simple-scan` — scan GUI
> - `nss-mdns` — `.local` name resolution (also repairs the `mdns_minimal` entry
>   in `/etc/nsswitch.conf`)

### Enable mDNS discovery

Avahi must be **enabled** (not just started), or the printer "vanishes" after a
reboot:

    sudo systemctl enable --now avahi-daemon.service

### Configure the printer

Run HP's setup tool against the IP. It detects the model, picks the driver, and
creates the CUPS queue. **Note the `/usr/bin/python`** — it bypasses the asdf
shim (see [Gotchas](#gotchas)):

    sudo /usr/bin/python /usr/bin/hp-setup -i 192.168.178.58

At the prompts: confirm it detected the Officejet 4630, press Enter to accept
the auto-selected driver, and **skip the HP test page** (`hp-testpage` also
breaks on asdf — we test below instead).

Verify the queue was created:

    lpstat -p -d
    lpstat -v        # device URI should be hp:/net/Officejet_4630_series?ip=...

### Print a test page

Set it as the default printer (per-user, no sudo) and print a built-in test page
(avoids HP's Python test tool):

    lpoptions -d Officejet_4630
    lp /usr/share/cups/data/default-testpage.pdf

### Configure the scanner

List SANE devices — an `airscan:` entry should appear:

    scanimage -L
    # device `airscan:e0:HP Officejet 4630 series [AA87B9]' is a eSCL ... scanner

Disable sane's broken built-in `escl` backend so `simple-scan` auto-picks
`sane-airscan` instead of failing on the wrong one:

    sudo sed -i 's/^escl$/#escl/' /etc/sane.d/dll.conf

Test scan from the CLI (blank platen is fine — proves the pipeline):

    scanimage -d 'airscan:e0:HP Officejet 4630 series [AA87B9]' \
        --mode Color --resolution 150 --format=png -o ~/scan-test.png

Day-to-day, just use the **`simple-scan`** GUI and pick the eSCL/airscan device.

### Gotchas

- **asdf shadows system Python.** The `hp-*` tools (`hp-setup`, `hp-testpage`,
  `hp-check`) have shebang `#!/usr/bin/env python`, which resolves to the asdf
  shim → `No version is set for command python`. Always invoke them as
  `sudo /usr/bin/python /usr/bin/hp-…`. Printing and scanning themselves are C
  programs and are unaffected.
- **Scan backends.** For this model `hpaio` (HPLIP) core-dumps on a network scan
  (`libpng error: No IDATs written`) and the built-in `escl` backend misparses
  the device and fails with `sane_start: Invalid argument`. `sane-airscan` is
  the one that works — install it and disable built-in `escl` as above.
- **Stale package db.** If `pacman -S hplip …` throws 404s / "invalid
  signature", the system db is stale from a partial upgrade — fix with a full
  `-Syu` first (see [pacman.md](pacman.md) and the troubleshooting section
  above).

## Bluetooth Troubleshooting

Reload bluetooth controller

    sudo modprobe -r btusb
    sudo modprobe btusb

Remove any possible bluetooth device blocks

    sudo rfkill block bluetooth && sleep 0.1 && sudo rfkill unblock bluetooth

Restart bluetooth via bluetoothctl

    echo -e 'show\npower off\npower on\nquit' | bluetoothctl

## TODO (WIP)

Get battery status of all connected devices (notebook battery, mouse, keyboard,
headphones, etc.)

    upower --dump

## References

- https://wiki.archlinux.org/title/Installation_guide
- https://wiki.archlinux.org/title/GRUB
- https://www.arcolinuxd.com/5-the-actual-installation-of-arch-linux-phase-1-bios/
- https://averagelinuxuser.com/ubuntu-vs-arch-linux/
- https://www.howtoforge.com/tutorial/how-to-install-arch-linux-with-full-disk-encryption/
- https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Keyfiles
