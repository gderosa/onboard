#!/bin/sh

if [ ! -d "$ONBOARD_DATADIR" ]; then
	ONBOARD_DATADIR=/home/onboard/.onboard
fi

VARRUN="$ONBOARD_DATADIR/var/run"

if [ ! -d "$VARRUN" ]; then
	mkdir -p $VARRUN
fi

ENV_SH=$ONBOARD_DATADIR/etc/config/env.sh

LANG='en_US.UTF-8' 
ONBOARD_ENVIRONMENT='production'

if [ -r "$ENV_SH" ]; then
	. $ENV_SH 
fi

export ONBOARD_ENVIRONMENT

