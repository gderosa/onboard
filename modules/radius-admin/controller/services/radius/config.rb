require 'facets/hash'
require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/config.:format' do
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/config',
        :title    => 'RADIUS Configuration',
        :format   => params[:format],
        :objects  => Service::RADIUS.read_conf
      )
    end

    put '/services/radius/config.:format' do
      oldconf = Service::RADIUS.read_conf
      newconf = oldconf.deep_merge params['conf']
      newconf['dbpass'] = oldconf['dbpass'] if params['conf']['dbpass'].empty?
          # empty password field means 'unchanged'
      Service::RADIUS.write_conf newconf
      actual_conf = Service::RADIUS.update_conf! # re-read
      Service::RADIUS.db_reconnect
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/config',
        :title    => 'RADIUS Configuration',
        :format   => params[:format],
        :objects  => actual_conf  
      )
    end

  end
end
