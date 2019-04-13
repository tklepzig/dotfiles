unzip -p <raspbian-image.img>  | sudo dd bs=4M of=</dev/sd-card> conv=fsync status=progress
