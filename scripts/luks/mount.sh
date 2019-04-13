#!/bin/bash

# $1 path to encrypted file (or device)
# $2 where to mount

sudo cryptsetup luksOpen $1 encrypted
sudo mount /dev/mapper/encrypted $2
