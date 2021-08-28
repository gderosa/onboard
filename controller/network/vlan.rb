require 'pp'
require 'sinatra/base'

require 'onboard/network/interface'

class OnBoard::Controller

  get '/network/vlan.:format' do
    objects = OnBoard::Network::Interface.getAll.sort_by(
      &OnBoard::Network::Interface::PREFERRED_ORDER
    )
    format(
      :path     => '/network/vlan',
      :format   => params[:format],
      :objects  => objects,
      :title    => 'VLAN 802.1Q trunks'
    )
  end

  # An example params is found in doc/
  put '/network/interfaces.:format' do
    current_interfaces = OnBoard::Network::Interface.getAll

    params['netifs'].each_pair do |ifname, ifhash|
      interface = current_interfaces.detect {|i| i.name == ifname}
      # In browser context, a checkbox param is simply absent (null/nil) for "unchecked".
      # In (JSON) API context, we want "active": false to be explicit, before bringing a network interface down!
      interface.modify_from_HTTP_request(ifhash, :safe_updown => (params[:format] != 'html'))
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

end
