#!/bin/sh

. `dirname $0`/common.sh

export LANG
export ONBOARD_ENVIRONMENT

thin -C config.yml -R config.ru start --pid $ONBOARD_DATADIR/var/run/thin.pid
sync
thin -C config6.yml -R config.ru start --pid $ONBOARD_DATADIR/var/run/thin6.pid
sync

