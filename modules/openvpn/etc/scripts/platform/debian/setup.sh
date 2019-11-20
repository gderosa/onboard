#!/bin/bash

# TODO: DRY

PROJECT_ROOT=${1:-'.'}
APP_USER=${2:-'onboard'}

SCRIPTDIR=$PROJECT_ROOT/etc/scripts

# apt-get update
apt-get -y install openvpn

enable_onboard_modules() {
    rm -f modules/easy-rsa/.disable
    rm -f modules/openvpn/.disable
    touch modules/easy-rsa/.enable
    touch modules/openvpn/.enable
    chown $APP_USER modules/easy-rsa/.enable
    chown $APP_USER modules/openvpn/.enable
}


export DEBIAN_FRONTEND=noninteractive

cd $PROJECT_ROOT

enable_onboard_modules

systemctl stop margay

su - $APP_USER -c "
    cd $PROJECT_ROOT
    ./etc/scripts/bundle-with.rb openvpn easy-rsa
    bundle install
"

systemctl start margay

