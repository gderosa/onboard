require 'yaml'
require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/config.:format' do
      format(
        :module => 'radius-admin',
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
        :module => 'radius-admin',
        :path => '/services/radius/config',
        :format => params[:format],
        :objects  => h
      )
    end

    get '/services/radius/users.:format' do
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users',
        :format   => params[:format],
        :objects  => nil # no CamelCase here :)
      )
    end

    post '/services/radius/users.:format' do
      msg = handle_errors{Service::RADIUS::Check.insert(params)} 
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users',
        :format   => params[:format],
        :objects  => nil,
        :msg      => msg
      )
    end

    get '/services/radius/accounting.:format' do
      params.update Pagination.normalize(params)
      format(
        :module => 'radius-admin',
        :path => '/services/radius/accounting',
        :format => params[:format],
        :objects  => Service::RADIUS::Accounting.get(params)           
      )
    end

  end
end
