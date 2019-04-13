#!/bin/bash

# $1 path to encrypted file (will be created) (or device (then skip dd!))

dd if=/dev/urandom of=$1 bs=1M count=1024
sudo cryptsetup -c aes-xts-plain64 -s 512 -h sha512 -y luksFormat $1
sudo cryptsetup luksOpen $1 encrypted
sudo mkfs.ext4 /dev/mapper/encrypted
sudo cryptsetup luksClose encrypted

#apt-get update && apt-get install -y pwgen vim cryptsetup-bin ntfs-3g
