For install bash completion on MacOS: Run `xcode-select --install`
https://apple.stackexchange.com/questions/312754/how-to-disable-lock-screen-hotkey-command-ctr-q-in-high-sierra
http://osxdaily.com/2014/07/10/set-screen-saver-keyboard-shortcut-mac/

## Use touch id for sudo

```
# Make file writable
sudo chmod 644 /etc/pam.d/sudo

# Open the sudo utility
sudo vi /etc/pam.d/sudo

# Add the following as the first line
auth sufficient pam_tid.so
```
