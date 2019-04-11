#!/bin/bash

# TODO: DRY

PROJECT_ROOT=${1:-'.'}
APP_USER=${2:-'onboard'}

# apt-get update
apt-get -y install openvpn

# TODO: unprivileged part!

enable_onboard_modules() {
    cd $ONBOARD_ROOT/modules/
    rm -f easy-rsa/.disable
    rm -f openvpn/.disable
    touch easy-rsa/.enable
    touch openvpn/.enable
}


export DEBIAN_FRONTEND=noninteractive

cd $PROJECT_ROOT

enable_onboard_modules

systemctl stop margay

./etc/scripts/bundle-with.rb openvpn easy-rsa
bundle install

systemctl start margay

