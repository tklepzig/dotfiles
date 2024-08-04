# Manjaro

## Write ISO to USB Stick

    sudo dd bs=4M if=/path/to/manjaro.iso of=/dev/drive status=progress oflag=sync

> Get list of drives:
>
>     sudo fdisk -l
