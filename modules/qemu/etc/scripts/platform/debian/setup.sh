#!/bin/bash

PROJECT_ROOT=${1:-`pwd`}
APP_USER=${2:-'onboard'}
APP_GROUP=$APP_USER

SCRIPTDIR=$PROJECT_ROOT/etc/scripts

enable_onboard_modules() {
	cd $PROJECT_ROOT/modules/
	rm -f jqueryFileTree/.disable
	rm -f qemu/.disable
	# rm -f glusterfs/.disable  # DEPRECATED
	touch jqueryFileTree/.enable
	touch qemu/.enable
	# touch glusterfs/.enable  # DEPRECATED
}

. $PROJECT_ROOT/etc/scripts/platform/debian/_upgrade_to_bullseye.sh

apt-get -y install qemu-system-x86 qemu-utils ruby-rmagick

adduser $APP_USER kvm
enable_onboard_modules

# See Documentation/virtual/kvm/nested-vmx.txt
# from Linux kernel source, or:
# https://github.com/torvalds/linux/blob/master/Documentation/virtual/kvm/nested-vmx.txt
if [ ! -f /etc/modprobe.d/kvm-intel-nested.conf ]; then
    echo 'options kvm-intel nested=1' > /etc/modprobe.d/kvm-intel-nested.conf
fi

su - $APP_USER -c "
cd
mkdir -p files/QEMU
mkdir -p files/ISO
cd $PROJECT_ROOT
./etc/scripts/bundle-with.rb qemu jqueryFileTree
bundle install
"

systemctl stop margay
systemctl start margay

. $SCRIPTDIR/_restore_dns.sh

