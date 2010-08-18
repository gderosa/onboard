#!/bin/sh

# You may set ONBOARD_ROOTDIR and ONBOARD_DATADIR in the environment
# to existent directories in order to customize this script's behavior;
# ONBOARD_HOME will be unused in such case.

ONBOARD_HOME=/home/onboard 

RSYNC_SWITCHES="-a"

if [ ! -d "$ONBOARD_ROOTDIR" ] ; then
	ONBOARD_ROOTDIR=$ONBOARD_HOME/onboard
fi
if [ ! -d "$ONBOARD_DATADIR" ] ; then
	ONBOARD_DATADIR=$ONBOARD_HOME/.onboard
fi

mkdir -p $ONBOARD_DATADIR/etc/config

rsync \
	--exclude config/network/dnsmasq/defaults \
	$RSYNC_SWITCHES $ONBOARD_ROOTDIR/etc/config $ONBOARD_DATADIR/etc/ \

rsync $RSYNC_SWITCHES $ONBOARD_ROOTDIR/modules/openvpn/etc/config $ONBOARD_DATADIR/etc/


mkdir -p "$ONBOARD_DATADIR/var/lib/crypto/easy-rsa/keys"
rsync $RSYNC_SWITCHES \
	$ONBOARD_ROOTDIR/modules/easy-rsa/easy-rsa/2.0/keys 	\
	$ONBOARD_DATADIR/var/lib/crypto/easy-rsa/		\


