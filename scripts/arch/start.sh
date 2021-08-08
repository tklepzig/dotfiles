if [ -z $1 ]
then
	echo "Usage: start.sh SSID"
	exit
fi

loadkeys de-latin1
setfont ter-132n
timedatectl set-ntp true
timedatectl set-timezone Europe/Berlin
iwctl station wlan0 connect $1
