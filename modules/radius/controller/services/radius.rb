require 'yaml'
require 'sinatra/base'

require 'onboard/service/radius'

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

    put '/services/radius/config.:format' do
      h = {}
      %w{dbhost dbname dbuser dbpass}.each do |key|
        h[key] = params[key]
      end
      File.open \
          "#{Service::RADIUS::CONFFILE}", 'w' do |f|
        f.write h.to_yaml
      end
      format(
        :module => 'radius',
        :path => '/services/radius/config',
        :format => params[:format],
        :objects  => []
      )
    end


  end

end
