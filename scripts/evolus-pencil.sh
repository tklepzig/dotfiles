#!/bin/bash

cd /tmp

if [ ! -f evoluspencil_2.0.5_all.deb ]; then
    wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/evoluspencil/evoluspencil_2.0.5_all.deb
fi

sudo dpkg -i evoluspencil_2.0.5_all.deb
sudo apt-get -fy install
