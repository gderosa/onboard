#!/bin/sh

ENV_SH=`dirname $0`/env.sh

LANG='en_US.UTF-8' 

if [ -r $ENV_SH ]; then
	. $ENV_SH 
fi

export LANG

thin -C config.yml -R config.ru start
thin -C config6.yml -R config.ru start


