require 'sinatra/base'

class OnBoard
  class Controller < Sinatra::Base
    get '/network/access-control/hotspot-wizard.:format' do
      format(
        :module => 'hotspot-wiz',
        :path => '/network/access-control/hotspot-wiz',
        :format => params[:format],
        :objects  => {},
        :title => "Hotspot all-in-one Configuration"
      )
    end
  end
end
