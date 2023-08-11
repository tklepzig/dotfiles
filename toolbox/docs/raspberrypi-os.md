# Raspberry Pi

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
