#!/bin/sh
. /etc/chilli/functions

[ -e "/var/run/chilli.iptables" ] && sh /var/run/chilli.iptables 2>/dev/null
rm -f /var/run/chilli.iptables 2>/dev/null

IF=$(basename $DEV)

# EDIT: do no add firewall rules to make 
# first configuration/test/debug easier
# (the captive portal itself is not iptables-based but TUN interface based)
	
ipt() {
    return
    opt=$1; shift
    echo "iptables -D $*" >> /var/run/chilli.iptables
    iptables $opt $*
}

ipt_in() {
    return
    ipt -I INPUT -i $IF $*
}

[ -n "$DHCPIF" ] && {

    [ -n "$UAMPORT" -a "$UAMPORT" != "0" ] && \
	ipt_in -p tcp -m tcp --dport $UAMPORT --dst $ADDR -j ACCEPT

    [ -n "$UAMUIPORT" -a "$UAMUIPORT" != "0" ] && \
	ipt_in -p tcp -m tcp --dport $UAMUIPORT --dst $ADDR -j ACCEPT

    [ -n "HS_TCP_PORTS" ] && {
	for port in $HS_TCP_PORTS; do
	    ipt_in -p tcp -m tcp --dport $port --dst $ADDR -j ACCEPT
	done
    }
    
    ipt_in -p udp -d 255.255.255.255 --destination-port 67:68 -j ACCEPT
    ipt_in -p udp --dst $ADDR --dport 53 -j ACCEPT

    ipt -A INPUT -i $IF --dst $ADDR -j DROP
    ipt -A INPUT -i $IF -j DROP

    ipt -I FORWARD -i $DHCPIF -j DROP
    ipt -I FORWARD -o $DHCPIF -j DROP
    ipt -I FORWARD -i $IF -j ACCEPT
    ipt -I FORWARD -o $IF -j ACCEPT

    # Help out conntrack to not get confused
    ipt -I PREROUTING -t raw -j NOTRACK -i $DHCPIF
    ipt -I OUTPUT -t raw -j NOTRACK -o $DHCPIF

    # Help out MTU issues with PPPoE or Mesh
    ipt -I FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    ipt -I FORWARD -t mangle -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

    [ "$HS_LAN_ACCESS" != "on" -a "$HS_LAN_ACCESS" != "allow" ] && \
	ipt -I FORWARD -i $IF -o \! $HS_WANIF -j DROP

    [ "$HS_LOCAL_DNS" = "on" ] && \
	ipt -I PREROUTING -t nat -i $IF -p udp --dport 53 -j DNAT --to-destination $ADDR
}

# site specific stuff optional
[ -e /etc/chilli/ipup.sh ] && . /etc/chilli/ipup.sh
