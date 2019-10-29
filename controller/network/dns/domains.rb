require 'sinatra/base'

require 'onboard/network/dnsmasq'

class OnBoard
  class Controller

    get "/network/dns/domains.:format" do
      dnsmasq = Network::Dnsmasq.new
      dnsmasq.parse_dns_conf(
        "#{Network::Dnsmasq::CONFDIR_CURRENT}/domains.conf"
      )
      dnsmasq.parse_dns_cmdline
      format(
        :path     => 'network/dns/domains',
        :format   => params[:format],
        :objects  => dnsmasq,
        :title    => 'DNS: domains'
      )
    end

    put "/network/dns/domains.:format" do
      dnsmasq = OnBoard::Network::Dnsmasq.new
      msg = dnsmasq.write_domains_conf_from_HTTP_request(params)
      if msg[:err]
        status 409
      else
        OnBoard::PLATFORM::restart_dnsmasq(OnBoard::Network::Dnsmasq::CONFDIR + '/new')
      end

      # read updated conf
      dnsmasq = OnBoard::Network::Dnsmasq.new
      dnsmasq.parse_dns_conf(
        "#{Network::Dnsmasq::CONFDIR_CURRENT}/domains.conf"
      )
      dnsmasq.parse_dns_cmdline
      format(
        :path     => 'network/dns/domains',
        :format   => params[:format],
        :objects  => dnsmasq,
        :msg      => msg,
        :title    => 'DNS: domains'
      )
    end

  end
end
