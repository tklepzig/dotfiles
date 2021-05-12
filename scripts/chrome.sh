#!/bin/bash

pushd /tmp > /dev/null

if [ ! -f google-chrome-stable_current_amd64.deb ]; then
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
fi

sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get -fy install

popd > /dev/null
