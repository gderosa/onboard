require 'yaml'
require 'sinatra/base'

require 'onboard/service/hotspotlogin'

class OnBoard

  class Controller < Sinatra::Base

    get '/services/hotspotlogin.:format' do
      format(
        :module => 'hotspotlogin',
        :path => '/services/hotspotlogin',
        :format => params[:format],
        :objects  => Service::HotSpotLogin.data
      )
    end

    put '/services/hotspotlogin.:format' do
      if params['change']
        Service::HotSpotLogin.change_from_HTTP_request!(params)
      elsif params['start']
      elsif params['stop']
      elsif (params['reload'] or params['restart'])
      end
      format(
        :module => 'hotspotlogin',
        :path => '/services/hotspotlogin',
        :format => params[:format],
        :objects  => Service::HotSpotLogin.data
      )
    end

  end

end
