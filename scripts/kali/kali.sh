#!/bin/bash

sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
sudo apt-get -y update
sudo apt-get -y install git libpcap-dev libssl-dev aircrack-ng wifite dmitry macchanger patch

# bully
wget https://github.com/aanarchyy/bully/archive/master.zip && unzip master.zip
cd bully*/
cd src/
make
sudo make install  
cd ../..

# mdk3
git clone git://git.kali.org/packages/mdk3.git
cd mdk3
patch < ../mdk3-v6.patch  # patch the source to get rid of "undefined reference to pthread_create" while doing make
make
sudo make install
cd ..

# necessary to make wash working...
sudo mkdir /etc/reaver


