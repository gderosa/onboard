require 'sinatra/base'

require 'onboard/network/access-control/chilli'

class OnBoard

  class Controller < Sinatra::Base

    get '/network/access-control/chilli.:format' do
      all = OnBoard::Network::AccessControl::Chilli.getAll()
      format(
        :module => 'chilli',
        :path => '/network/access-control/chilli',
        :format => params[:format],
        :objects  => all
      )
    end

    get '/network/access-control/chilli/:ifname.:format' do
      all = OnBoard::Network::AccessControl::Chilli.getAll()
      format(
        :module => 'chilli',
        :path => '/network/access-control/chilli/ifconfig',
        :format => params[:format],
        :objects  => all.detect{|x| x.conf['dhcpif'] == params[:ifname]} 
      )
    end
   
  end

end
