#!/bin/sh

#default
LANG='en_US.UTF-8' 

# allow a customization of the environment in env.sh
[ -r env.sh ] && . env.sh

export LANG

thin -C config.yml -R config.ru start
