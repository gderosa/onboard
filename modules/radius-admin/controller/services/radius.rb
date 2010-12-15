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
      use_pagination_defaults
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users',
        :format   => params[:format],
        :objects  => Service::RADIUS::User.get(params)
      )
    end

    get '/services/radius/groups.:format' do
      use_pagination_defaults
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/groups',
        :format   => params[:format],
        :objects  => Service::RADIUS::Group.get(params)
      )
    end
   

    post '/services/radius/users.:format' do
      use_pagination_defaults
      msg = handle_errors{Service::RADIUS::Check.insert(params)} 
      if msg[:ok] and not msg[:err]
        msg = handle_errors{Service::RADIUS::Reply.insert(params)}
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users',
        :format   => params[:format],
        :objects  => Service::RADIUS::User.get(params),
        :msg      => msg
      )
    end

    get '/services/radius/users/:userid.:format' do
      user = Service::RADIUS::User.new(params[:userid])
      user.retrieve_attributes_from_db
      not_found unless user.found?
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users/user',
        :format   => params[:format],
        :objects  => {
          'conf'    => Service::RADIUS.conf,
          'user'    => user
        },
      )
    end

    put '/services/radius/users/:userid.:format' do
      user = Service::RADIUS::User.new(params[:userid])
      user.retrieve_attributes_from_db
      not_found unless user.found?
      msg = handle_errors do 
        user.update(params)
        user.retrieve_attributes_from_db
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users/user',
        :format   => params[:format],
        :msg      => msg,
        :objects  => {
          'conf'    => Service::RADIUS.conf,
          'user'    => user
        }
      )
    end

    get '/services/radius/accounting.:format' do
      use_pagination_defaults
      format(
        :module => 'radius-admin',
        :path => '/services/radius/accounting',
        :format => params[:format],
        :objects  => Service::RADIUS::Accounting.get(params)           
      )
    end

  end
end
