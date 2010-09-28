require 'pp'
require 'sinatra/base'

require 'onboard/network/interface'

class OnBoard::Controller

  get '/network/interfaces.:format' do
    objects = OnBoard::Network::Interface.getAll.sort_by(
      &OnBoard::Network::Interface::PREFERRED_ORDER 
    ) 
    format(
      :path     => '/network/interfaces',
      :format   => params[:format],
      :objects  => objects,
      :title    => 'Network interfaces'
    )
  end

  get '/network/interfaces/:ifname.:format' do
    format(
      :path => '/network/interfaces',
      :format => params[:format],
      :title    => "Network interfaces: #{params[:ifname]}",
      :objects  => OnBoard::Network::Interface.getAll.select do |iface|
        iface.name == params[:ifname]
      end
    )
  end

  # An example params is found in doc/  
  put '/network/interfaces.:format' do
    current_interfaces = OnBoard::Network::Interface.getAll

    params['netifs'].each_pair do |ifname, ifhash|
      interface = current_interfaces.detect {|i| i.name == ifname}
      interface.modify_from_HTTP_request(ifhash) 
    end

    updated_objects = OnBoard::Network::Interface.getAll.sort_by(
        &OnBoard::Network::Interface::PREFERRED_ORDER
    )

    format(
      :path     => '/network/interfaces',
      :format   => params[:format],
      :title    => 'Network Interfaces',
      :objects  => updated_objects
    ) 
  end

  put '/network/interfaces/:ifname.:format' do
    ifname = params[:ifname]
    current_interface = OnBoard::Network::Interface.getAll.detect do |iface|
      iface.name == ifname
    end

    begin
      current_interface.modify_from_HTTP_request params['netifs'][ifname]
    rescue NoMethodError # in case of nil, skip!
    end

    format(
      :path     => '/network/interfaces',
      :format   => params[:format],
      :title    => "Network interfaces: #{ifname}",
      :objects  => OnBoard::Network::Interface.getAll.select do |iface|
        iface.name == ifname
      end
    ) 
  end

end
