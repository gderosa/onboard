#!/bin/sh

#default
LANG='en_US.UTF-8' 

# allow a customization of the environment in env.sh
[ -r env.sh ] && . env.sh

export LANG

sysctl net.ipv6.bindv6only=0 # allow a single thin instance to listen on IPv4 and IPv6

thin -C config.yml -R config.ru start
