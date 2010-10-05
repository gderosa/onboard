require 'sinatra/base'

class OnBoard

  class Controller < Sinatra::Base

    get '/network/openvpn/client-side-configuration.:format' do
      all_vpns                = Network::OpenVPN::VPN.getAll
      all_interfaces          = nil
      # use cached data if possible
      if Network::OpenVPN::VPN.class_variables.include? :@@all_interfaces
        all_interfaces = 
            Network::OpenVPN::VPN.class_variable_get :@@all_interfaces
        if !(all_interfaces.respond_to? :length and all_interfaces.length > 0)
          all_interfaces = Network::Interface.getAll
        end
      end
      objects = {
        :vpns               => all_vpns,
        :network_interfaces => all_interfaces
      }
      format(
        :module   => 'openvpn',
        :path     => '/network/openvpn/client-side-configuration',
        :format   => params[:format], 
        :objects  => objects,
        :title    => 'Cient-side configuration Wizard'
      )
    end

  end

end
