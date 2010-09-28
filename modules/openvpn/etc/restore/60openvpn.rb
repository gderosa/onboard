require 'onboard/system/log'
require 'onboard/network/openvpn/vpn'
require 'onboard/network/interface'

OnBoard::Network::OpenVPN::VPN.restore()


# Aren't upscripts used instead?

# re-run interfaces restore, after new TAP interfaces have been created
#Thread.new do
#  sleep 5
#  OnBoard::Network::Interface.restore()
#end

