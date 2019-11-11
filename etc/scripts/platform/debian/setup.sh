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

PROJECT_ROOT=${1:-`pwd`}
APP_USER=${2:-'onboard'}

CONFDIR=~$APP_USER/.onboard

install_conffiles() {
    # See README file in doc/sysadm/examples/ .
    install -bvC -m 644 doc/sysadm/examples/etc/dnsmasq.conf            /etc/
    install -bvC -m 644 doc/sysadm/examples/etc/sysctl.conf             /etc/

    install -bvC -m 644 doc/sysadm/examples/etc/usb_modeswitch.conf     /etc/
    install -bvC -m 644 doc/sysadm/examples/etc/usb_modeswitch.d/*:*    /etc/usb_modeswitch.d/
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
        if [ ! -d $CONFDIR ]; then
            # If this is a fresh install (or a vagrant up after a vagrant destroy),
            # the .enable file is likely stale; and we don't want to enable a module for which
            # the dependencies are not installed yet.
            rm -f $dir/.enable
        fi
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

setup_nginx() {
    apt-get -y install nginx-light ssl-cert
    rm -fv /etc/nginx/sites-enabled/default  # just a symlink
    install -bvC -m 644 doc/sysadm/examples/etc/nginx/sites-available/margay /etc/nginx/sites-available/
    ln -svf ../sites-available/margay /etc/nginx/sites-enabled/
    systemctl reload nginx
}


export DEBIAN_FRONTEND=noninteractive

cd $PROJECT_ROOT

apt-get update
apt-get -y upgrade
apt-get -y install ruby ruby-dev ruby-erubis ruby-rack ruby-rack-protection ruby-locale ruby-facets sudo iproute2 iptables bridge-utils pciutils usbutils usb-modeswitch dhcpcd5 dnsmasq resolvconf locales ifrename build-essential ca-certificates ntp psmisc
# Optional, but useful tools when ssh'ing
apt-get -y install vim-nox mc

install_conffiles

# Let's not use the old Debian one...
gem install --no-rdoc --no-ri  -v '~> 2' bundler

su - $APP_USER -c "
    cd $PROJECT_ROOT
    # Module names are also Gemfile groups
    echo Running: bundle install $(bundle_without_all_opts) ...
    bundle install $(bundle_without_all_opts)
"

modprobe nf_conntrack
service procps restart

disable_app_modules

disable_dhcpcd_master

# Circumvent this bug:
# http://debian.2.n7.nabble.com/Bug-732920-procps-sysctl-system-fails-to-load-etc-sysctl-conf-td3133311.html
sysctl --load=/etc/sysctl.conf
sysctl --load=$PROJECT_ROOT/doc/sysadm/examples/etc/sysctl.conf

# Disable the legacy SysV service, now "margay".
# Use "onboard.service", not simply "onboard", to not confuse with mere user login session...
if ( systemctl list-units --all | grep onboard.service ); then
    # Stop if running
    if ( systemctl status onboard.service ); then
        systemctl stop onboard.service
    fi
    systemctl disable onboard.service
fi

cat > /etc/systemd/system/margay.service <<EOF
[Unit]
Description=Margay Service
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$PROJECT_ROOT
Environment="APP_ENV=production"
ExecStart=/usr/bin/env ruby onboard.rb
SyslogIdentifier=margay
Restart=on-failure
# Other Restart options: always, on-abort, on-failure etc

[Install]
WantedBy=multi-user.target
EOF

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
SyslogIdentifier=margay-persist
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable margay
systemctl start margay

systemctl enable margay-persist
systemctl start margay-persist  # Also resume dnsmasq after reconfig, it's not optional!

cd $PROJECT_ROOT  # Apparently needed...

setup_nginx

# Remove packages conflicting with our DHCP management
dpkg -l | egrep '^i.\s+wicd-daemon' && apt-get -y remove wicd-daemon || true