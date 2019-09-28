#!/bin/bash

ONBOARD_USER=onboard
ONBOARD_GROUP=$ONBOARD_USER
ONBOARD_ROOT=/home/$ONBOARD_USER/onboard

enable_onboard_modules() {
	cd $ONBOARD_ROOT/modules/
	rm -f ap/.disable
	touch ap/.enable
}

apt-get -yq install hostapd

# The system(d) service is "masked" by default, which is okay for us ;)

enable_onboard_modules

# Maybe it won't need any specific extra gem
#su - $ONBOARD_USER -c "
#cd
#cd $ONBOARD_ROOT
#./etc/scripts/bundle-with.rb ap
#bundle install
#"

systemctl stop margay
systemctl start margay
