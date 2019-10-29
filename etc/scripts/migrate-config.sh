#!/bin/sh

# You may set ONBOARD_ROOTDIR and ONBOARD_DATADIR in the environment
# to existent directories in order to customize this script's behavior;
# ONBOARD_HOME will be unused in such case.

ONBOARD_HOME=/home/onboard

if [ ! -d "$ONBOARD_ROOTDIR" ] ; then
	ONBOARD_ROOTDIR=$ONBOARD_HOME/onboard
fi
if [ ! -d "$ONBOARD_DATADIR" ] ; then
	ONBOARD_DATADIR=$ONBOARD_HOME/.onboard
fi

mkdir -vp "$ONBOARD_DATADIR/etc/"

# Check if durectories exist and they are not symlink

if [ -d "$ONBOARD_ROOTDIR/etc/config" ]; then
	if [ ! -h "$ONBOARD_ROOTDIR/etc/config" ]; then
		mv -fv \
			$ONBOARD_ROOTDIR/etc/config $ONBOARD_DATADIR/etc/
		ln -sfv $ONBOARD_DATADIR/etc/config $ONBOARD_ROOTDIR/etc/config
	fi
fi

if [ -d "$ONBOARD_ROOTDIR/modules/openvpn/etc/config/network/openvpn" ]; then
	if [ ! -h "$ONBOARD_ROOTDIR/modules/openvpn/etc/config/network/openvpn" ]; then
		mkdir -vp $ONBOARD_DATADIR/etc/config/network/
		mv -fv \
			$ONBOARD_ROOTDIR/modules/openvpn/etc/config/network/openvpn \
			$ONBOARD_DATADIR/etc/config/network/
		ln -sfv \
			$ONBOARD_DATADIR/etc/config/network/openvpn \
			$ONBOARD_ROOTDIR/modules/openvpn/etc/config/network/openvpn
	fi
fi

if [ -d "$ONBOARD_ROOTDIR/modules/easy-rsa/easy-rsa/2.0/keys" ]; then
	if [ ! -h "$ONBOARD_ROOTDIR/modules/easy-rsa/easy-rsa/2.0/keys" ]; then
		mkdir -vp $ONBOARD_DATADIR/var/lib/crypto/easy-rsa/
		mv -fv \
			$ONBOARD_ROOTDIR/modules/easy-rsa/easy-rsa/2.0/keys \
			$ONBOARD_DATADIR/var/lib/crypto/easy-rsa/
		ln -sfv $ONBOARD_DATADIR/var/lib/crypto/easy-rsa/keys \
			$ONBOARD_ROOTDIR/modules/easy-rsa/easy-rsa/2.0/keys
	fi
fi


