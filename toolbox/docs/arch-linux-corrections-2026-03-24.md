# Arch Linux Doc Corrections (2026-03-24)

## 1. Removed `xorg-apps` from `pacstrap`

The `xorg-apps` meta-package no longer exists in the Arch repos. Install individual
xorg utilities as needed (e.g. `xorg-xrandr`, `xorg-xset`).

Reference: https://wiki.archlinux.org/title/Xorg

---

## 2. Added `keyboard` hook and fixed HOOKS syntax for encryption

The `keyboard` hook must be present **before** `keymap` in the initramfs hooks,
otherwise keyboard input may not work at all when entering the LUKS passphrase.

Also updated the syntax from the outdated quoted string to the correct array form:

```
# Before
HOOKS="... keymap encrypt"

# After
HOOKS=(... keyboard keymap encrypt)
```

Reference: https://wiki.archlinux.org/title/Mkinitcpio#Common_hooks
Reference: https://wiki.archlinux.org/title/Dm-crypt/System_configuration#mkinitcpio

---

## 3. Replaced `mkinitcpio -p linux` with `mkinitcpio -P`

`-p <preset>` still works but `-P` (regenerate all presets) is the modern
recommended invocation.

Reference: https://wiki.archlinux.org/title/Mkinitcpio

---

## 4. Removed duplicate `gdmap` from `pacman -S`

`gdmap` is an AUR package and was mistakenly listed in both the `pacman -S` line
and the AUR packages section. Removed from the `pacman -S` line.

---

## 5. Updated asdf installation to use AUR package

The old git-clone + `git describe --tags` approach is outdated. `asdf` is now
available as `asdf-vm` in the AUR:

```bash
git clone https://aur.archlinux.org/asdf-vm.git
cd asdf-vm
makepkg -sic
```

Reference: https://aur.archlinux.org/packages/asdf-vm

---

## 6. Fixed `cryptkey` filesystem type

Replaced `auto` with `ext4` as the filesystem type in the `cryptkey` kernel
parameter. The `auto` value is not reliably supported; the actual filesystem type
should be specified explicitly.

```
# Before
cryptkey=UUID=<UUID>:auto:/absolute/path/to/mykeyfile

# After
cryptkey=UUID=<UUID>:ext4:/absolute/path/to/mykeyfile
```

Reference: https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Keyfiles
