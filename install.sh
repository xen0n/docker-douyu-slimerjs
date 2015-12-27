#!/bin/bash

BUILD_DEPS="
build-essential git cmake ragel libasound2-dev libssl-dev libglib2.0-dev libpango1.0-dev
libgl1-mesa-dev libevent-dev libgtk2.0-dev libxrandr-dev libxrender-dev
libxcursor-dev libgles2-mesa-dev
paxctl
"

# configure apt-get
# Temporarily disable dpkg fsync to make building faster.                     
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
	echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi

export DEBIAN_FRONTEND=noninteractive

# install deps
sed -i 's/archive\.ubuntu\.com/cn.archive.ubuntu.com/' /etc/apt/sources.list
echo 'deb http://archive.canonical.com/ubuntu trusty partner' >> /etc/apt/sources.list
echo 'deb-src http://archive.canonical.com/ubuntu trusty partner' >> /etc/apt/sources.list
apt-get update -qq
apt-get install -qqy --no-install-recommends \
	xvfb adobe-flashplugin \
	${BUILD_DEPS}

# freshplayerplugin
cd /tmp
git clone https://github.com/xen0n/freshplayerplugin.git
cd freshplayerplugin
git checkout bb675e36154c4f84180ee4797def4417977a58da
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DWITH_HWDEC=0 -DWITH_LIBV4L2=0 -DWITH_GLES2=1 ..
make -j20

# replace the NPAPI flash plugin
mv ./libfreshwrapper-flashplayer.so /usr/lib/adobe-flashplugin/libflashplayer.so
cd ../..
rm -rf freshplayerplugin

# copy config
mkdir /root/.config
mv /build/freshwrapper.conf /root/.config/freshwrapper.conf

# slimerjs
wget -q http://download.slimerjs.org/releases/0.9.6/slimerjs-0.9.6-linux-x86_64.tar.bz2
cd /srv
tar xf /tmp/slimerjs-0.9.6-linux-x86_64.tar.bz2
rm /tmp/slimerjs-0.9.6-linux-x86_64.tar.bz2
mv slimerjs-0.9.6 slimerjs
paxctl -c -m ./slimerjs/xulrunner/xulrunner
paxctl -c -m ./slimerjs/xulrunner/plugin-container

# install scripts
mv /build/douyu.js /srv/douyu.js
mv /build/douyu-connector /usr/local/bin/douyu-connector

# cleanup
apt-get remove -qqy ${BUILD_DEPS}
apt-get autoremove -qqy
apt-get clean -qq
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup