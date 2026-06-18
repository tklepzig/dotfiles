# Raspberry Pi

## Bootstrap a fresh Pi (one-liner)

Once the OS is imaged and SSH is on (see below), provision the whole box —
dotfiles, languages via asdf — with `pi-setup.sh` at the repo root:

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/tklepzig/dotfiles/master/pi-setup.sh)"

It is idempotent (safe to re-run). The SD-card prep below has to happen first;
audio output (USB DAC) is a separate manual step — see "Audio output" below.

## Audio output (USB DAC via PipeWire)

The Pi 5 has no 3.5mm jack, so audio goes out a USB DAC (e.g. a UGREEN/C-Media
adapter — USB Audio Class, driverless). Plug it in **before boot** so ALSA
enumerates it cleanly. Bookworm uses PipeWire, and `mpv`/most apps play through
the **default sink**, so the job is just making the USB sink the default.

Find the sink id and check which is default (`*`):

    wpctl status        # under "Sinks:" — the default has a leading *

If the USB sink isn't already default (it often is), set it:

    wpctl set-default <ID>

WirePlumber persists this across reboots (state in `~/.local/state/wireplumber`).
For the default to apply to a **headless/service** context, that user's systemd
manager must be running at boot — `pi-setup.sh` already does `loginctl
enable-linger`, which also gives the service its `XDG_RUNTIME_DIR`.

Quick test (the real path apps use):

    mpv --no-video /usr/share/sounds/alsa/Front_Center.wav

If it's silent despite a correct default sink, the usual culprit is **volume**,
in two places — set both to 100% and persist:

    wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
    amixer -c <usb-card> sset Speaker 100% && alsactl store

Note: `mpv --audio-fallback-to-null` means a service can run "silently" with a
clean `systemctl status` — don't trust "active"; trigger a sound and listen.

## Desktop (i3 needs X11)

`pi-setup.sh` installs the full i3 desktop (i3 + kitty + the status-bar,
launcher, lock, notification, audio, brightness and network-applet tooling that
mirrors `i3/install` on Arch), but i3 is an X11 window manager and Bookworm on
the Pi 5 defaults to Wayland. Switch to X11 before using the desktop (a
headless-only Pi can skip this):

    sudo raspi-config   # Advanced Options -> Wayland -> X11, then reboot

## Write OS to sd card

unzip -p <raspbian-image-archive.zip> | sudo dd bs=4M of=</dev/sd-card> conv=fsync status=progress

## Enable SSH

Create file `ssh` in root of boot partition of sd card

## Setup WiFi

Create file `wpa_supplicant.conf` in root of boot partition of sd card (fill in the necessary values)

    country=DE
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    network={
    			ssid="<ssid>"
    			psk=<hashed password>
    			key_mgmt=WPA-PSK
    }

For getting hashed password, run `wpa_passphrase "<ssid>"` and then enter the password.

## Setup default user pi

Create file `userconf` in root of boot partition of sd card (fill in the necessary values)

    pi:<encrypted password>

For getting encrypted password, run `echo 'mypassword' | openssl passwd -6 -stdin`

## VNC

show the same screen on hdmi and vncclient

    sudo apt-get install x11vnc
    x11vnc -display :0 [ -usepw -listen IP_of_pi -allow allowed_ip_address ]

> -display : screen number to get
> -usepw : use password security
> -listen : IP address of server (Pi IP)
> -allow : allowed client IPs (client IP, in your case Mac IP address)

## Echo GPU/CPU temperature

    cpu=$(</sys/class/thermal/thermal_zone0/temp)
    echo "$(date) @ $(hostname)"
    echo "-------------------------------------------"
    echo "GPU => $(/opt/vc/bin/vcgencmd measure_temp)"
    echo "CPU => $((cpu/1000))'C"

## Issues installing ruby via asdf

Install

    libyaml-dev
    libtool
    libffi-dev
