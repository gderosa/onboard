#!/bin/sh

if [ "x$ONBOARD_USERNAME" = "x" ]; then
	ONBOARD_USERNAME=onboard
fi

if [ ! -d "$ONBOARD_DATADIR" ]; then
	ONBOARD_DATADIR=/home/onboard/.onboard
fi

chown -R $ONBOARD_USERNAME $ONBOARD_DATADIR

# NOTE NOTE NOTE: now, Operating System's /var/run is used to store 
# pidfiles: it SHOULD be mounted in RAM (aka tmpfs) to avoid spurious 
# Thin::PidFileExist exceptions after power failures and so on, 
# which ultimately prevent application startup at all!!
#
# See also https://thin.lighthouseapp.com/projects/7212/tickets/137-empty-pid-files-should-be-ignoreddeleted-instead-of-raising-thinpidfileexist
#

ONBOARD_VARRUN="/var/run/onboard"

ONBOARD_VARLOG=$ONBOARD_DATADIR/var/log

ENV_SH=$ONBOARD_DATADIR/etc/config/env.sh

LANG='en_US.UTF-8' 
ONBOARD_ENVIRONMENT='production'

if [ -r "$ENV_SH" ]; then
	. $ENV_SH 
fi

for dir in $ONBOARD_VARRUN, $ONBOARD_VARLOG; do
	if [ ! -d "$dir" ]; then
		(mkdir -p $dir 2> /dev/null) || (
			sudo mkdir -p $dir
			sudo chown onboard:onboard $dir
		)
	fi
done


export ONBOARD_ENVIRONMENT

