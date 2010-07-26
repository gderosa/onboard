require 'onboard/network/openvpn/vpn'
require 'onboard/network/interface'

OnBoard::Network::OpenVPN::VPN.restore()


# re-run interfaces restore, after new TAP interfaces have been created
Thread.new do
  sleep 5
  OnBoard::Network::Interface.restore()
end

