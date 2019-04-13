#!/bin/bash

# TODO: DRY

PROJECT_ROOT=${1:-'.'}
APP_USER=${2:-'onboard'}
MODULES="radius-core radius-admin chilli hotspotlogin mail"

# apt-get update
apt-get -y install freeradius freeradius-mysql mysql-server ruby-sequel ruby-mysql diffutils \
    libjson-c3 libssl1.1 iptables haserl adduser  # dependencies of the self-built coova-chilli deb package

dpkg -i modules/chilli/blobs/deb/coova-chilli_1.4_amd64.deb  # This will of course vary for Rasbperry PI...

enable_modules() {
    for module in $MODULES; do
        rm -f modules/$module/.disable
        touch modules/$module/.enable
        chown $APP_USER modules/$module/.enable
    done
}

export DEBIAN_FRONTEND=noninteractive

cd $PROJECT_ROOT

enable_modules

systemctl stop margay

su - $APP_USER -c "
    cd $PROJECT_ROOT
    ./etc/scripts/bundle-with.rb $MODULES
    bundle install
"

systemctl start margay

