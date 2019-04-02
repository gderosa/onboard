# This assumes the user OnBoard/Margay will run as already exists in the system
# and can sudo,
# and software is copied / placed in the relevant directory with proper
# ownership/permissions. This script takes
# control from there. Another script may be implemented for that very initial
# bootstrap instead.

PROJECT_ROOT=${1:-'.'}

cd $PROJECT_ROOT

install_conffiles() {
	install -bvC -m 755 doc/sysadm/examples/etc/init.d/onboard 		/etc/init.d/
	install -bvC -m 644 doc/sysadm/examples/etc/dnsmasq.conf 		/etc/
	install -bvC -m 644 doc/sysadm/examples/etc/sysctl.conf		    /etc/
}

apt-get update
# TODO: lighttpd removed: NGINX!
apt-get -y install ruby ruby-dev ruby-erubis ruby-rack ruby-rack-protection ruby-locale ruby-facets sudo iproute iptables bridge-utils pciutils dhcpcd5 dnsmasq resolvconf locales ifrename build-essential ca-certificates ntp psmisc

gem install --no-ri --no-rdoc bundler

install_conffiles