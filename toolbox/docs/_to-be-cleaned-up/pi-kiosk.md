# Kiosk Mode

## Software

    sudo apt-get install x11-xserver-utils unclutter chromium-browser
    
> (latest chromium: https://www.raspberrypi.org/forums/viewtopic.php?t=121195)


## Kiosk Autostart: 

    vi ~/kiosk.sh

```
# do not forget chmod 777
#!/bin/bash

xset s off
xset -dpms
xset s noblank
unclutter -display :0 -noevents -grab &

/usr/bin/chromium-browser --incognito --noerrdialogs --disable-session-crashed-bubble --disable-infobars --kiosk http://localhost &

```


    sudo vi ~/.config/autostart/kiosk.desktop

```
[Desktop Entry]
Type=Application
Exec=/home/pi/kiosk.sh
Hidden=false
X-GNOME-Autostart-enabled=true
Name=Kiosk
Comment=Start Kiosk Mode
```
