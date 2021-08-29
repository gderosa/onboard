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

  put '/network/vlan.:format' do
    OnBoard::Network::Interface.set_802_1q_trunks(params['vlan']['trunk'])

    updated_objects = OnBoard::Network::Interface.getAll.sort_by(
        &OnBoard::Network::Interface::PREFERRED_ORDER
    )

    format(
      :path     => '/network/vlan',
      :format   => params[:format],
      :title    => 'VLAN 802.1Q trunks',
      :objects  => updated_objects
    )
  end

end
