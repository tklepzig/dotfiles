sudo apt install cec-utils
Set active HDMI n source: tx 1F:82:n0:00
Power off: echo "standby 0" | cec-client RPI -s -d 1
Power on: echo "on 0" | cec-client RPI -s -d 1
Get Power State: echo "pow 0" | cec-client RPI -s -d 1
