Create container file `container` (e.g. 500 MB)

    dd if=/dev/urandom of=container bs=1M count=500

Encrypt

    sudo cryptsetup -s 512 -h sha512 -y -i 5000 luksFormat container

> Encrypt device: Replace container with device, e.g. /dev/sda

Open container

    sudo cryptsetup open container encrypted

Format container

    sudo mkfs.ext4 /dev/mapper/encrypted

Mount container

    sudo mount /dev/mapper/encrypted /path/to/mountpoint

Unmount container

    sudo umount /path/to/mountpoint

Close container

    sudo cryptsetup close encrypted
