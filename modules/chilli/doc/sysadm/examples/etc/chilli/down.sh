#!/bin/sh
# Coova Chilli - David Bird <david@coova.com>
# Licensed under the GPL, see http://coova.org/
# down.sh /dev/tun0 192.168.0.10 255.255.255.0

. /etc/chilli/functions

[ -e "/var/run/chilli.iptables" ] && sh /var/run/chilli.iptables 2>/dev/null
rm -f /var/run/chilli.iptables 2>/dev/null

# site specific stuff optional
[ -e /etc/chilli/ipdown.sh ] && . /etc/chilli/ipdown.sh
