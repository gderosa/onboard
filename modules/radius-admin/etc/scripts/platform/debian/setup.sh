#!/bin/bash

# TODO: DRY

PROJECT_ROOT=${1:-`pwd`}
APP_USER=${2:-'onboard'}
SCRIPTDIR=$PROJECT_ROOT/etc/scripts
MODULES="radius-core radius-admin chilli hotspotlogin mail"
FREERADIUS_CONF_NEW=$PROJECT_ROOT/modules/radius-admin/doc/sysadm/examples/etc/freeradius
FREERADIUS_CONF_SYS=/etc/freeradius
FREERADIUS_CONF_BAK=/etc/freeradius.before-margay

cd $PROJECT_ROOT

# apt-get update
apt-get -y install freeradius freeradius-mysql default-mysql-server ruby-sequel ruby-mysql2 diffutils \
    libjson-c3 libssl1.1 iptables haserl adduser  # dependencies of the self-built coova-chilli deb package

# --force-confnew will overwrite (without prompting) files in /etc/default and similar.
# This should be safe. Custom configs are all in our very own .onboard dir!

dpkg -i --force-confnew modules/chilli/blobs/deb/coova-chilli_1.4_amd64.deb
    # This will of course vary for Rasbperry PI...

enable_modules() {
    for module in $MODULES; do
        rm -f modules/$module/.disable
        touch modules/$module/.enable
        chown $APP_USER modules/$module/.enable
    done
}

setup_freeradius() {
    # FreeRADIUS
    echo "Checking if FreeRADIUS configuration needs updating..."
    if ! (diff -rq $FREERADIUS_CONF_NEW $FREERADIUS_CONF_SYS)
    then
        systemctl stop freeradius
        echo "Removing obsolete backups (if present)..."
        rm -rf $FREERADIUS_CONF_BAK
        if [ -d $FREERADIUS_CONF_SYS ]; then
            echo "Back up of FreeRADIUS configuration..."
            mv $FREERADIUS_CONF_SYS $FREERADIUS_CONF_BAK
        fi
        echo "Installing new FreeRADIUS configuration..."
        cp -rfa $FREERADIUS_CONF_NEW /etc/
        chown -R freerad:freerad $FREERADIUS_CONF_SYS
        echo "(Re)starting FreeRADIUS..."
        systemctl start freeradius
    fi
}

export DEBIAN_FRONTEND=noninteractive

enable_modules

# WARNING: this relies on mysql root localhost with no password!
# WARNING: (of course  allowed from local Unix root user only - unix socket)
# TODO: handle when this assumption is not met?
mysql < modules/radius-admin/doc/sysadm/examples/admin.mysql
mysql radius < modules/radius-admin/doc/sysadm/examples/schema3.mysql

setup_freeradius

systemctl stop margay

su - $APP_USER -c "
    cd $PROJECT_ROOT
    ./etc/scripts/bundle-with.rb $MODULES
    bundle install
"

systemctl start margay

. $SCRIPTDIR/_restore_dns.sh

