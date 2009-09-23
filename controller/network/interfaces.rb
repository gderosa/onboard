require 'pp'
require 'sinatra/base'

require 'onboard/network/interface'

class OnBoard::Controller

  get '/network/interfaces.:format' do
    format(
      :path => '/network/interfaces',
      :format => params[:format],
      :objects  => OnBoard::Network::Interface.getAll
    )
  end

  # An example params is found in doc/  
  put '/network/interfaces.:format' do
    current_interfaces = OnBoard::Network::Interface.getAll
    params['netifs'].each_pair do |ifname, ifhash|
      interface = current_interfaces.detect {|i| i.name == ifname}
      interface.modify_from_HTTP_request(ifhash) 
    end
    status(202)                       # HTTP "Accepted"
    headers(
      "Location"      => request.path_info,
      "Pragma"        => "no-cache",  # HTTP/1.0
      "Cache-Control" => "no-cache"   # HTTP/1.1
    ) 
    format(
      :path => '/network/interfaces',
      :format => params[:format],
      :objects  => OnBoard::Network::Interface.getAll
    ) 
  end

  get "/network/interfaces/:ifname.:format" do
    interfaces  = OnBoard::Network::Interface.getAll
    names       = interfaces.map {|netif| netif.name}
    raise Sinatra::NotFound unless names.include? params[:ifname]
    format(
      :path   => 'network/interfaces',
      :format => params[:format],
      :objects  => interfaces.find do |netif|
        netif.name  == params[:ifname]
      end
    )
  end

  get "/network/interfaces/:ifname/ip.:format" do
    interfaces  = OnBoard::Network::Interface.getAll
    names       = interfaces.map {|netif| netif.name}
    raise Sinatra::NotFound unless names.include? params[:ifname]
    format(
      :path   => 'network/interfaces/ip',
      :format => params[:format],
      :objects  => (interfaces.find do |netif|
        netif.name  == params[:ifname]
      end).ip
    )
  end

  get "/network/interfaces/:ifname/ip/:ip.:format" do
    interfaces  = OnBoard::Network::Interface.getAll
    names       = interfaces.map {|netif| netif.name}
    raise Sinatra::NotFound unless names.include? params[:ifname]
    interface   = interfaces.find {|netif| netif.name == params[:ifname]}
    ipstrings   = interface.ip.map {|ip| ip.addr.to_s} 
    raise Sinatra::NotFound unless ipstrings.include? params[:ip] 
    ipobject    = interface.ip.find {|ip| ip.addr.to_s == params[:ip]} 

    format(
      :path     => 'network/interfaces/ip',
      :format   => params[:format],
      :objects  => ipobject
    )
  end

end
