#!/bin/sh

ENV_SH=`dirname $0`/env.sh

LANG='en_US.UTF-8' 
ONBOARD_ENVIRONMENT='production'

if [ -r $ENV_SH ]; then
	. $ENV_SH 
fi

export LANG
export ONBOARD_ENVIRONMENT

thin -C config.yml -R config.ru start
sync
thin -C config6.yml -R config.ru start
sync

