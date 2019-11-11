#!/bin/bash

ONBOARD_ROOT=${1:-`pwd`}
ONBOARD_USER=${2:-'onboard'}
ONBOARD_GROUP=$ONBOARD_USER

enable_onboard_modules() {
	cd $ONBOARD_ROOT/modules/
	rm -f jqueryFileTree/.disable
	rm -f qemu/.disable
	# rm -f glusterfs/.disable  # DEPRECATED
	touch jqueryFileTree/.enable
	touch qemu/.enable
	# touch glusterfs/.enable  # DEPRECATED
}

apt-get -y install qemu-system-x86 qemu-utils ruby-rmagick

adduser $ONBOARD_USER kvm
enable_onboard_modules

# See Documentation/virtual/kvm/nested-vmx.txt
# from Linux kernel source, or:
# https://github.com/torvalds/linux/blob/master/Documentation/virtual/kvm/nested-vmx.txt
if [ ! -f /etc/modprobe.d/kvm-intel-nested.conf ]; then
    echo 'options kvm-intel nested=1' > /etc/modprobe.d/kvm-intel-nested.conf
fi

su - $ONBOARD_USER -c "
cd
mkdir -p files/QEMU
mkdir -p files/ISO
cd $ONBOARD_ROOT
./etc/scripts/bundle-with.rb qemu jqueryFileTree
bundle install
"

systemctl stop margay
systemctl start margay
