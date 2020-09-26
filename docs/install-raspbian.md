unzip -p <raspbian-image-archive.zip>  | sudo dd bs=4M of=</dev/sd-card> conv=fsync status=progress

Enable SSH: create file "ssh" in root of boot partition of sd card
Setup WiFi: create file "wpa_supplicant.conf" in root of boot partition of sd card (fill in the necessary values):

```
country=DE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
       ssid="<ssid>"
       psk=<hashed password>
       key_mgmt=WPA-PSK
}
```
For getting hashed password: Run `wpa_passphrase "<ssid>" "<password>"`
