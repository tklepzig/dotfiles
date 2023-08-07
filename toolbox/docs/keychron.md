# Enable F-Keys on Linux

Test if this command fixes the issue and enables the Fn + F-key-combos

    # run as root (e.g. sudo -i)
    echo 2 > /sys/module/hid_apple/parameters/fnmode

Depending on the mode the keyboard is in, you should now be able to use the F-keys by simply pressing them, and the Multimedia keys by pressing fn + F-key (or the other way round). To switch the default mode of the F-keys to Function- or Multimedia-mode, press and hold fn + X + L for 4 seconds.

If everything works as expected, you can make the change permanent by creating the file `/etc/modprobe.d/hid_apple.conf` and adding the following line

    options hid_apple fnmode=2

and running

    sudo mkinitcpio -p linux
    # or sudo mkinitcpio -P to (re-)generate all existing presets?
