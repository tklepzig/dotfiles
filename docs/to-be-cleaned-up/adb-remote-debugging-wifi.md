1. Get IP of device (e.g. `adb shell ifconfig wlan0`)
2. ENable Remote Debugging over TCP: `adb tcpip 5555`
3. Connect to device over TCP: `adb connect <IP, see above>:5555`
4. Head to `chrome://inspect` and search for device. If not visible, refresh the list by running `adb devices`.
5. Back to USB: `adb usb`
> from https://remysharp.com/2016/12/17/chrome-remote-debugging-over-wifi
