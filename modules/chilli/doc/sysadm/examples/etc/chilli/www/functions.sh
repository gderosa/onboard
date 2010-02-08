# -*- mode: shell-script -*-
# Copyright (C) 2009 Coova Technologies, LLC. <support@coova.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#  
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# default, before configuration
HS_ENABLED=true

. /etc/chilli/functions

CHILLI_RESPONSE=/usr/sbin/chilli_response
CHILLI_QUERY=/usr/sbin/chilli_query
CHILLI_PROXY=/usr/sbin/chilli_proxy

# default, after configuration

uci_command=$(ls /bin/uci 2>/dev/null)

getconfig() {
    [ "$uci_command" != "" ] && {
	uci get miniportal.$1
	return;
    }

    eval "echo \$HS_$(echo $1|tr 'a-z' 'A-Z')"
}

pkg_attr_file() {
    p=/etc/chilli/pkg.
    while [ "$1" != "" ]; do
	[ -e "$p$1" ] && { cat $p$1; return; }
	shift;
    done
    echo
}

register_with_pkg() {
    type=$1; shift
    user=$1; shift
    pass=$1; shift
    regout=$(pkg_attr_file $* default|$CHILLI_PROXY --register status new_$type user "$user" pass "$pass")
    echo $regout
}

#config miniportal
#  option  enabled=true
#  option  reg_mode=[self|tos]
#  option  openidauth=
#  option  owner_email=
#  option  uamsecret=
