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
        :objects  => Service::HotSpotLogin.data,
        :title  => 'Hotspot Login page'
      )
    end

    get '/services/hotspotlogin/logo_preview' do
      file = Service::HotSpotLogin.read_conf['logo']
      if file
        send_file file
      else
        not_found
      end
    end

    put '/services/hotspotlogin.:format' do
      msg = {:ok => true}
      begin
        if params['change']
          Service::HotSpotLogin.change_from_HTTP_request!(params)
          Service::HotSpotLogin.restart! if Service::HotSpotLogin.running?
        elsif params['start']
          Service::HotSpotLogin.start!
        elsif params['stop']
          Service::HotSpotLogin.stop!
        elsif (params['reload'] or params['restart'])
          Service::HotSpotLogin.restart!
        end
      rescue Service::HotSpotLogin::BadRequest
        status 400 # HTTP Bad Request
        msg = {:err => $!}
      end
      format(
        :module => 'hotspotlogin',
        :path => '/services/hotspotlogin',
        :format => params[:format],
        :objects  => Service::HotSpotLogin.data,
        :msg => msg,
        :title  => 'Hotspot Login page'
      )
    end

  end

end
