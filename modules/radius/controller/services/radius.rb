require 'yaml'
require 'sinatra/base'

require 'onboard/service/hotspotlogin'

class OnBoard

  class Controller < Sinatra::Base

    get '/services/radius/config.:format' do
      format(
        :module => 'radius',
        :path => '/services/radius/config',
        :format => params[:format],
        :objects  => []
      )
    end

  end

end
