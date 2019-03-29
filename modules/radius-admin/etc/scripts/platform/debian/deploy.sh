#!/bin/sh

# This script will potentially replace the deb package of vemarsas/margay-setup

apt-get -y update
apt-get -y -f install
apt-get -y install freeradius freeradius-mysql mysql-server coova-chilli ruby-sequel ruby-mysql2 diffutils

# Insprired by https://github.com/vemarsas/margay-setup/blob/master/debian/margay-setup-hotspot.postinst

set -e

ONBOARD_USER=onboard
ONBOARD_GROUP=$ONBOARD_USER
ONBOARD_ROOT=/home/$ONBOARD_USER/onboard
FREERADIUS_CONF_NEW=$ONBOARD_ROOT/modules/radius-admin/doc/sysadm/examples/etc/freeradius
FREERADIUS_CONF_SYS=/etc/freeradius
FREERADIUS_CONF_BAK=/etc/freeradius.before-margay
ONBOARD_RADIUS_MODULES="radius-admin radius-core"

enable_onboard_modules() {
	cd $ONBOARD_ROOT/modules/
	for i in $ONBOARD_HOTSPOT_MODULES; do
		rm -f $i/.disable
		touch $i/.enable
	done
}


echo "Checking if FreeRADIUS configuration needs updating..."
if ! (diff -q $FREERADIUS_CONF_NEW $FREERADIUS_CONF_SYS)
then
    service freeradius stop
    echo "Removing obsolete backups (if present)..."
    rm -rf $FREERADIUS_CONF_BAK
    if [ -d $FREERADIUS_CONF_SYS ]; then 
        echo "Back up of FreeRADIUS configuration..."
        mv $FREERADIUS_CONF_SYS $FREERADIUS_CONF_BAK
    fi
    echo "Installing new FreeRADIUS configuration..."
    cp -rfa $FREERADIUS_CONF_NEW /etc/ 
    service freeradius start
fi
enable_onboard_modules
su - $ONBOARD_USER -c "
cd $ONBOARD_ROOT
./etc/scripts/bundle-with.rb $ONBOARD_HOTSPOT_MODULES
bundle install
./stop.sh && ./start.sh
"
