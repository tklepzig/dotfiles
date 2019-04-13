# $1 where to mount

sudo umount $1
sudo cryptsetup luksClose encrypted
