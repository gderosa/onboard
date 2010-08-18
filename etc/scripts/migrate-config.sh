
ONBOARD_HOME=/home/onboard

if [ ! -d "$ONBOARD_ROOTDIR" ] ; then
	ONBOARD_ROOTDIR=$ONBOARD_HOME/onboard
fi
if [ ! -d "$ONBOARD_DATADIR" ] ; then
	ONBOARD_DATADIR=$ONBOARD_HOME/.onboard
fi

mkdir -p $ONBOARD_DATADIR/etc/config
cp -rvf $ONBOARD_ROOTDIR/etc/config $ONBOARD_DATADIR/etc/
cp -rvf $ONBOARD_ROOTDIR/modules/openvpn/etc/config $ONBOARD_DATADIR/etc/config

mkdir -p "$ONBOARD_DATADIR/var/lib/var/lib/crypto/easy-rsa/keys"
cp -rvf \
	$ONBOARD_ROOTDIR/modules/easy-rsa/easy-rsa/2.0/keys 		\
	$ONBOARD_DATADIR/var/lib/var/lib/crypto/easy-rsa/		\


