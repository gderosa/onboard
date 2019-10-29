require 'sinatra/base'

require 'onboard/network/dnsmasq'

class OnBoard::Controller

  get "/network/dns.:format" do
    dnsmasq = OnBoard::Network::Dnsmasq.new
    dnsmasq.parse_dns_conf
    dnsmasq.parse_dns_cmdline
    format(
      :path     => 'network/dns',
      :format   => params[:format],
      :objects  => dnsmasq,
      :title    => 'DNS'
    )
  end

  put "/network/dns.:format" do
    dnsmasq = OnBoard::Network::Dnsmasq.new
    msg = dnsmasq.write_dns_conf_from_HTTP_request(params)
    if msg[:err]
      status 409
    else
      OnBoard::PLATFORM::restart_dnsmasq(OnBoard::Network::Dnsmasq::CONFDIR + '/new')
    end

    # read updated conf
    dnsmasq = OnBoard::Network::Dnsmasq.new
    dnsmasq.parse_dns_conf
    dnsmasq.parse_dns_cmdline
    format(
      :path     => 'network/dns',
      :format   => params[:format],
      :objects  => dnsmasq,
      :msg      => msg,
      :title    => 'DNS'
    )
  end

end
