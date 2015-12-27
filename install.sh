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
apt-get remove -qqy \
	${BUILD_DEPS} \
	libdrm-dev libegl1-mesa-dev libexpat1-dev libfontconfig1-dev \
	libfreetype6-dev libharfbuzz-dev libice-dev libmirclient-dev \
	libmirprotobuf-dev libpcre3-dev libpixman-1-dev libpng12-dev \
	libprotobuf-dev libpthread-stubs0-dev libsm-dev libstdc++-4.8-dev \
	libwayland-dev libx11-dev libx11-xcb-dev libxau-dev libxcb-dri2-0-dev \
	libxcb-dri3-dev libxcb-glx0-dev libxcb-present-dev libxcb-randr0-dev \
	libxcb-render0-dev libxcb-shape0-dev libxcb-shm0-dev libxcb-sync-dev \
	libxcb-xfixes0-dev libxcb1-dev libxcomposite-dev libxdamage-dev \
	libxdmcp-dev libxext-dev libxfixes-dev libxi-dev libxinerama-dev \
	libxshmfence-dev libxxf86vm-dev mesa-common-dev mircommon-dev \
	x11proto-composite-dev x11proto-core-dev x11proto-damage-dev \
	x11proto-dri2-dev x11proto-fixes-dev x11proto-gl-dev x11proto-input-dev \
	x11proto-kb-dev x11proto-randr-dev x11proto-render-dev x11proto-xext-dev \
	x11proto-xf86vidmode-dev x11proto-xinerama-dev xtrans-dev zlib1g-dev

apt-get clean -qq
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup
