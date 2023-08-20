WIP

ensure having adb
adb push -p zip-file /sdcard/
Get into Recovery Mode (TWRP)
Install image, follow TWRP instructions

# from https://maruos.com/docs/user/twrp.html

Installing TWRP
There are many ways to install TWRP, but here's one that works well.

Download TWRP for your device (here's a link (opens new window)where you can search for your device)

Connect your device to your computer, enable USB Debugging, and follow the instructions below:

Make sure to substitute the correct name of the file you downloaded for anything in brackets.

Open up a terminal and run the following:

$ adb reboot bootloader
You are now in the bootloader.

Check your bootloader lock state on the line "LOCK STATE - ...".

If it says "unlocked", skip to step 4. If it says "locked", you will need to first unlock your bootloader:

$ fastboot oem unlock
Make sure you follow the on-screen instructions to verify the unlock.

After unlocking, hit the Power button to reboot your device. After it boots back up, re-enable USB debugging and reboot to the bootloader again:

$ adb reboot bootloader
Flash TWRP:

$ fastboot flash recovery <twrp filename>.img
If above command failed with no recovery partition error, you can try the following command:

$ fastboot flash boot <twrp filename>.img
Use the Volume Up button on your device to cycle through the bootloader options to "Recovery mode" and hit the Power button to boot into TWRP recovery

Swipe right to let TWRP modify the system partition (this lets TWRP avoid being overwritten by the stock recovery when you reboot)

Tap "Reboot", then tap "System" to reboot

Tip: You may be asked to install SuperSU to root your device. If you know what rooting your device means and want to have it rooted then go ahead. Otherwise, it's best to tap "Do Not Install".

# from https://maruos.com/docs/devices/hammerhead.html#install

Install
#Prerequisites
adb installed on your computer (see LineageOS's guide (opens new window))
TWRP custom recovery installed on your device
#Install Maru via TWRP
#Download
Download (opens new window)the latest update zip for your device (it will look like maru-v0.x.y-update-hammerhead-<sha256>.zip)

(Optional) If you would like to restore access to the Play store, you can download a third-party Google Apps zip and install it alongside Maru during this installation process.
Push the update zip to your device by opening up a terminal (Linux or Mac) or Command Prompt (Windows) and running the following:

$ adb push -p maru-v0.x.y-update-hammerhead-xxxxxxxx.zip /sdcard/
TIP

You can also just download the update zip directly from your device's browser so you don't need to push it from your PC to your device.

#Backup
Reboot to TWRP custom recovery:
$ adb reboot recovery
You will now be in TWRP recovery.

Take a complete back-up before proceeding so it's easy to revert back if needed. Just tap Backup > Swipe to Backup.
#Install
When you are ready to install Maru, do the following:

Tap "Install"

Tap the Maru update zip you pushed earlier (you may need to scroll down)

Swipe right to confirm flash of Maru

Hit back till you are at the main screen, then Wipe

Swipe right to Factory Reset (this will still keep your back-ups on your sdcard)

Tap Reboot System
