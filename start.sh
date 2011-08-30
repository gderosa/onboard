#!/bin/sh

. `dirname $0`/common.sh

export LANG
export ONBOARD_ENVIRONMENT
export RUBYOPT='-E utf-8'

thin -C config.yml -R config.ru start --pid $ONBOARD_VARRUN/thin.pid --log $ONBOARD_VARLOG/thin.log
sync
# IPv6, in case of bindv6only Linux configuration
thin -C config6.yml -R config.ru start --pid $ONBOARD_VARRUN/thin6.pid --log $ONBOARD_VARLOG/thin6.log
sync

