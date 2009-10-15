require 'sinatra/base'

class OnBoard
  module Network
    module OpenVPN
      autoload :VPN, 'onboard/network/openvpn/vpn'
    end
  end
end

class OnBoard::Controller < Sinatra::Base
  get '/network/openvpn/vpn.:format' do
    vpns = OnBoard::Network::OpenVPN::VPN.getAll()
    format(
      :module => 'openvpn',
      :path => '/network/openvpn/vpn',
      :format => params[:format],
      :objects  => vpns
    )
  end
end
