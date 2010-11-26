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
        :objects  => Service::RADIUS.read_conf
      )
    end

    put '/services/radius/config.:format' do
      h = Service::RADIUS.read_conf
      %w{dbhost dbname dbuser}.each do |key|
        h[key] = params[key]
      end
      h['dbpass'] = params['dbpass'] if params['dbpass'].length > 0
          # empty password field means 'unchanged'
      Service::RADIUS.write_conf h
      Service::RADIUS.db_reconnect
      format(
        :module => 'radius',
        :path => '/services/radius/config',
        :format => params[:format],
        :objects  => h
      )
    end

    get '/services/radius/accounting.:format' do
      params[:page] = 1 unless params[:page]
      params[:per_page] = 10 unless params[:per_page] # TODO: use a constant
      format(
        :module => 'radius',
        :path => '/services/radius/accounting',
        :format => params[:format],
        :objects  => Service::RADIUS::Accounting.get(params) 
      )
    end

  end
end
