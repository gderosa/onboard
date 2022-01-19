require 'pp'
require 'sinatra/base'

require 'onboard/network/interface'
require 'onboard/network/bridge'
require 'onboard/extensions/string'

class OnBoard::Controller

  get "/network/bridges.:format" do
    interfaces  = OnBoard::Network::Interface.getAll
    bridges     = interfaces.select {|i| i.type == 'bridge'}
    format(
      :path     => 'network/bridges',
      :format   => params[:format],
      :objects  => bridges,
      :title    => 'Bridges'
    )
  end

  post "/network/bridges.:format" do
    msg = OnBoard::Network::Bridge.brctl(params['brctl'])
    msg[:ok] ? status(201) : status(400)
    headers(
      'Location:' =>
          "/network/bridges/#{params['brctl']['addbr']}.#{params['format']}"
    )
    interfaces  = OnBoard::Network::Interface.getAll
    bridges     = interfaces.select {|i| i.type == 'bridge'}
    format(
      :path     => 'network/bridges',
      :format   => params[:format],
      :objects  => bridges,
      :title    => 'Bridges',
      :msg      => msg
    )
  end

  put '/network/bridges.:format' do
    # pp params
    interfaces = OnBoard::Network::Interface.getAll
    if params['netifs'].respond_to? :each_pair
      params['netifs'].each_pair do |ifname, ifhash| # PUT/[POST] params
        interface = interfaces.detect {|i| i.name == ifname}
        interface.modify_from_HTTP_request(ifhash)
      end
    end
    OnBoard::Network::Bridge.brctl(params['brctl'])
    # update info
    interfaces = OnBoard::Network::Interface.getAll
    bridges = interfaces.select {|i| i.type == 'bridge'}
    # send response
    if [nil, false, [], {}].include? params['netifs']
      status(204)                     # HTTP "No Content"
      halt
    end
    status(202)                       # HTTP "Accepted"
    headers(
      "Location"      => request.path_info,
      "Pragma"        => "no-cache",  # HTTP/1.0
      "Cache-Control" => "no-cache"   # HTTP/1.1
    )
    format(
      :path     => '/network/bridges',
      :format   => params[:format],
      :objects  => bridges,
      :title    => 'Bridges'
    )
  end

  get "/network/bridges/:brname.:format" do
    interfaces  = OnBoard::Network::Interface.getAll
    bridge      = interfaces.find do |netif|
      netif.type == 'bridge' and netif.name == params['brname']
    end
    raise Sinatra::NotFound unless bridge
    format(
      :path     => 'network/bridge',
      :format   => params[:format],
      :objects  => {:bridge => bridge, :all_interfaces => interfaces},
      :title    => "Bridge: #{params['brname']}"
    )
  end

  put '/network/bridges/:brname.:format' do
    interfaces = OnBoard::Network::Interface.getAll
    params['netifs'].each_pair do |ifname, ifhash| # PUT/[POST] params
      interface = interfaces.detect {|i| i.name == ifname}
      interface.modify_from_HTTP_request(ifhash)
    end
    OnBoard::Network::Bridge.brctl(params['brctl'])
    # update info
    interfaces = OnBoard::Network::Interface.getAll
    bridge = interfaces.find do |netif|
      netif.name == params['brname']
    end
    format(
      :path => '/network/bridge',
      :format => params[:format],
      :objects  => {:bridge => bridge, :all_interfaces => interfaces},
      :title    => "Bridge: #{params['brname']}"
    )
  end

  delete '/network/bridges/:brname.:format' do
    bridges = OnBoard::Network::Interface.getAll.select {|i| i.type == 'bridge'}
    if bridges.detect {|br| br.name == params['brname']}
      redirection = "/network/bridges.#{params['format']}"
      OnBoard::Network::Bridge.brctl(
        'delbr' => params['brname']
      )
      status(303)                       # HTTP "See Other"
      headers('Location' => redirection)
      format(
        :path     => '/303',
        :format   => params['format'],
        :objects  => redirection
      )
    else
      raise Sinatra::NotFound
    end
  end

end
