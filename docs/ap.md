`sudo apt-get install -y dnsmasq hostapd`  
`sudo vi /etc/dhcpcd.conf`  
add line: `denyinterfaces wlan0`  


#### /etc/network/interfaces (nur anpassen, wenn etwas nicht geht, ansonsten file unverändert lassen) --> erst am Ende bearbeiten

```
# interfaces(5) file used by ifup(8) and ifdown(8)

# Please note that this file is written to be used with dhcpcd
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'

# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# Localhost
auto lo
iface lo inet loopback

# Ethernet
auto eth0
iface eth0 inet dhcp
dns-nameservers 10.49.1.1 10.49.10.5

allow-hotplug wlan0  
iface wlan0 inet static
	address 192.168.1.1
	netmask 255.255.255.0
```

`sudo service dhcpcd restart`  
`sudo ifdown wlan0; sudo ifup wlan0`  


#### /etc/hostapd/hostapd.conf 

```
# This is the name of the WiFi interface we configured above
interface=wlan0

# Use the nl80211 driver with the brcmfmac driver
driver=nl80211

# This is the name of the network
ssid=Lucy

# Use the 2.4GHz band
hw_mode=g

# Use channel 6
channel=6

# Enable 802.11n
ieee80211n=1

# Enable WMM
wmm_enabled=1

# Enable 40MHz channels with 20ns guard interval
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]

# Accept all MAC addresses
macaddr_acl=0

# Use WPA authentication
auth_algs=1

# Require clients to know the network name
ignore_broadcast_ssid=0

# Use WPA2
wpa=2

# Use a pre-shared key
wpa_key_mgmt=WPA-PSK

# The network passphrase
wpa_passphrase=12345678

# Use AES, instead of TKIP
rsn_pairwise=CCMP
```

check: `sudo /usr/sbin/hostapd /etc/hostapd/hostapd.conf`  

`sudo vi /etc/default/hostapd`  

`#DAEMON_CONF=""` --> `DAEMON_CONF="/etc/hostapd/hostapd.conf"`  

`sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig`  

#### /etc/dnsmasq.conf

```
# DHCP-Server aktiv für WLAN-Interface
interface=wlan0

# DHCP-Server nicht aktiv für bestehendes Netzwerk
no-dhcp-interface=eth0

# IPv4-Adressbereich und Lease-Time
dhcp-range=192.168.1.100,192.168.1.150,24h

# DNS
dhcp-option=option:dns-server,192.168.1.1
```

# Wrapping up

`sudo service hostapd start`  
`sudo service dnsmasq start `  

## -- OR --

`sudo reboot`  