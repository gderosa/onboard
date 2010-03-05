require 'sinatra/base'

require 'onboard/service/hotspotlogin'

class OnBoard

  class Controller < Sinatra::Base

    get '/services/hotspotlogin.:format' do
      format(
        :module => 'hotspotlogin',
        :path => '/services/hotspotlogin',
        :format => params[:format],
        :objects  => Service::HotSpotLogin.getAll()
      )
    end

  end

end
