require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/users.:format' do
      use_pagination_defaults
      raduserinfo = Service::RADIUS::User.get(params)
      users = raduserinfo['users']
      users.each do |u| 
        u.retrieve_attributes_from_db if !u.check or u.check.length == 0
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users',
        :format   => params[:format],
        :objects  => raduserinfo
      )
    end

    post '/services/radius/users.:format' do
      use_pagination_defaults
      msg = handle_errors do
        name  = params['check']['User-Name']
        Service::RADIUS::Check.insert(params)
        user  = Service::RADIUS::User.new(name)
        user.update_reply_attributes(params)
        user.update_personal_data(params)
      end
      raduserinfo = Service::RADIUS::User.get(params)
      users = raduserinfo['users']
      users.each do |u| 
        u.retrieve_attributes_from_db if !u.check or u.check.length == 0
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users',
        :format   => params[:format],
        :objects  => raduserinfo,
        :msg      => msg
      )
    end

    get '/services/radius/users/:userid.:format' do
      user = Service::RADIUS::User.new(params[:userid])
      user.retrieve_attributes_from_db
      user.retrieve_group_membership_from_db
      user.retrieve_personal_info_from_db
      not_found unless user.found?
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users/user',
        :format   => params[:format],
        :objects  => {
          'user'    => user
        },
      )
    end

    put '/services/radius/users/:userid.:format' do
      user = Service::RADIUS::User.new(params[:userid])
      user.retrieve_attributes_from_db
      user.retrieve_group_membership_from_db
      not_found unless user.found?
      msg = handle_errors do 
        user.update(params)
        user.retrieve_attributes_from_db
        user.retrieve_group_membership_from_db
        user.retrieve_personal_info_from_db
      end
      unless user.found?
        msg[:warn] = "User has no longer any attribute!"
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users/user',
        :format   => params[:format],
        :msg      => msg,
        :objects  => {
          'user'    => user
        }
      )
    end

  end
end
