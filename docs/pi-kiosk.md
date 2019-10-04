# Kiosk Mode

## Software

    sudo apt-get install x11-xserver-utils unclutter chromium-browser
    
> (latest chromium: https://www.raspberrypi.org/forums/viewtopic.php?t=121195)


## Kiosk Autostart: 

    vi ~/kiosk.sh

```
xset s off         # don't activate screensaver
xset -dpms         # disable DPMS (Energy Star) features.
xset s noblank     # don't blank the video device
unclutter -idle 0  # hide cursor

chromium-browser --noerrdialogs --disable-session-crashed-bubble --disable-infobars --kiosk http://localhost:82
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
