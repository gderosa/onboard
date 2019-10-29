require 'sinatra/base'

require 'onboard/network/dnsmasq'

# this should be always safe: it's a no-op if a current
# configuration already exists
OnBoard::Network::Dnsmasq.init_conf

class OnBoard::Controller

  get "/network/dhcp-server.:format" do
    dnsmasq = OnBoard::Network::Dnsmasq.new
    dnsmasq.parse_dhcp_conf
    dnsmasq.parse_dhcp_leasefile
    format(
      :path     => 'network/dhcp-server',
      :format   => params[:format],
      :objects  => dnsmasq,
      :title    => 'DHCP Server'
    )
  end

  put "/network/dhcp-server.:format" do
    dnsmasq = OnBoard::Network::Dnsmasq.new
    msg = dnsmasq.write_dhcp_conf_from_HTTP_request(params)
    if msg[:err]
      status 409
    else
      OnBoard::PLATFORM::restart_dnsmasq(OnBoard::Network::Dnsmasq::CONFDIR + '/new')
    end

    # read updated conf
    dnsmasq = OnBoard::Network::Dnsmasq.new
    dnsmasq.parse_dhcp_conf
    dnsmasq.parse_dhcp_leasefile
    format(
      :path     => 'network/dhcp-server',
      :format   => params[:format],
      :objects  => dnsmasq,
      :msg      => msg,
      :title    => 'DHCP Server'
    )
  end

end
