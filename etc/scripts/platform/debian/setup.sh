#!/bin/bash

# This assumes that the user
# OnBoard/Margay will run-as
# already exists in the system and can sudo,
# and software is copied / placed in the relevant directory with proper
# ownership/permissions. This script takes
# control from there.
# Another script may be implemented for that very initial
# bootstrap instead, and will likely not be used by Vagrant but only for
# deployment on real hardware or "naked" VMs.

# echo $* # DEBUG

PROJECT_ROOT=${1:-'.'}
APP_USER=${2:-'onboard'}

install_conffiles() {
	install -bvC -m 644 doc/sysadm/examples/etc/dnsmasq.conf 		/etc/
	install -bvC -m 644 doc/sysadm/examples/etc/sysctl.conf		    /etc/
}

bundle_without_all_opts() {
	# Avoid --without (empty)
	without_opt=''
	groups=''
	for mod in `ls $PROJECT_ROOT/modules` ; do
		if [ -f $PROJECT_ROOT/modules/$mod/Gemfile ]; then
			without_opt='--without'
			groups="$groups $mod"
		fi
	done
	echo "$without_opt $groups" | xargs
}

disable_app_modules() {
	for dir in $PROJECT_ROOT/modules/* ; do
		if [ ! -f $dir/.enable ]; then
			file=$dir/.disable
			touch $file
			chown $APP_USER $file
		fi
	done
}

disable_dhcpcd_master() {
	# Even if no interface is configured with dhcp in /etc/network/interfaces,
	# dhcpcd is a system(d) service, that starts as just "dhcpcd" (master mode)
	# which is incompatible with onboard detection and control.
	if (systemctl status dhcpcd > /dev/null); then
		systemctl disable dhcpcd
	fi
}


export DEBIAN_FRONTEND=noninteractive

cd $PROJECT_ROOT

apt-get update
apt-get -y upgrade
# TODO: lighttpd removed: NGINX!
apt-get -y install ruby ruby-bundler ruby-dev ruby-erubis ruby-rack ruby-rack-protection ruby-locale ruby-facets sudo iproute iptables bridge-utils pciutils dhcpcd5 dnsmasq resolvconf locales ifrename build-essential ca-certificates ntp psmisc

install_conffiles

su - $APP_USER -c "
	cd $PROJECT_ROOT
	# Module names are also Gemfile groups
	echo Running: bundle install $(bundle_without_all_opts) \# This may take some time...
	bundle install $(bundle_without_all_opts)
"

modprobe nf_conntrack_ipv4
modprobe nf_conntrack_ipv6
service procps restart

disable_app_modules

disable_dhcpcd_master

# Circumvent this bug:
# http://debian.2.n7.nabble.com/Bug-732920-procps-sysctl-system-fails-to-load-etc-sysctl-conf-td3133311.html
sysctl --load=/etc/sysctl.conf
sysctl --load=$PROJECT_ROOT/doc/sysadm/examples/etc/sysctl.conf

# Disable the legacy SysV service, now "margay"
if ( systemctl list-units --all | grep onboard ); then
	# Stop if running
	if ( systemctl status onboard ); then
		systemctl stop onboard
	fi
	systemctl disable onboard
fi

cat > /etc/systemd/system/margay.service <<EOF
[Unit]
Description=Margay Service
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$PROJECT_ROOT
ExecStart=/usr/bin/env ruby onboard.rb
Restart=on-failure
# Other Restart options: or always, on-abort, on-failure etc

[Install]
WantedBy=multi-user.target
EOF

# TODO: fix persistence (and shutdown)
cat > /etc/systemd/system/margay-persist.service <<EOF
[Unit]
Description=Margay restore-persistent/teardown service
After=network.target

[Service]
Type=oneshot
User=$APP_USER
WorkingDirectory=$PROJECT_ROOT
ExecStart=/usr/bin/env ruby onboard.rb --restore --no-web
ExecStop=/usr/bin/env ruby onboard.rb --shutdown --no-web
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable margay
systemctl start margay

systemctl enable margay-persist
