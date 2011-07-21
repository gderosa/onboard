require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/users.:format' do
      use_pagination_defaults
      raduserinfo = {}
      msg = handle_errors do
        raduserinfo = Service::RADIUS::User.get(params)
      end
      users = raduserinfo['users'] || []
      users.each do |u| 
        u.retrieve_attributes_from_db if !u.check or u.check.length == 0
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users',
        :title    => "RADIUS Users",
        :format   => params[:format],
        :objects  => raduserinfo,
        :msg      => msg
      )
    end

    post '/services/radius/users.:format' do
      use_pagination_defaults
      name  = params['check']['User-Name']
      user  = Service::RADIUS::User.new(name) # blank slate
      msg = handle_errors do 
        Service::RADIUS::Check.insert(params)
        user.update_reply_attributes(params) 
        user.update_personal_data(params)
        user.upload_attachments(params) 
      end
      if msg[:ok] and not msg[:err] 
        status 201 # Created
        msg[:info] = %Q{User <a class="created" href="users/#{user.name}.#{params[:format]}">#{user.name}</a> has been created!}
      end
      raduserinfo = Service::RADIUS::User.get(params)
      users = raduserinfo['users']
      users.each do |u| 
        u.retrieve_attributes_from_db if !u.check or u.check.length == 0
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users',
        :title    => "RADIUS Users",
        :format   => params[:format],
        :objects  => raduserinfo,
        :msg      => msg
      )
    end

    get '/services/radius/users/:userid.:format' do
      user = Service::RADIUS::User.new(params[:userid])
      msg = {}
      msg = handle_errors do
        user.retrieve_attributes_from_db
        user.retrieve_group_membership_from_db
        user.retrieve_personal_info_from_db
        user.get_personal_attachment_info
        not_found unless user.found?
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users/user',
        :title    => "RADIUS User: #{params[:userid]}",
        :format   => params[:format],
        :objects  => {
          'user'    => user,
        },
        :msg      => msg
      )
    end

    put '/services/radius/users/:userid.:format' do
      user = Service::RADIUS::User.new(params[:userid])
      msg = handle_errors do
        user.retrieve_attributes_from_db
        user.retrieve_group_membership_from_db
        not_found unless user.found?
        user.update(params)
        user.retrieve_attributes_from_db
        user.retrieve_group_membership_from_db
        user.retrieve_personal_info_from_db
        user.get_personal_attachment_info
      end
      if !user.found? and !msg[:err] 
        msg[:warn] = "User has no longer any attribute!"
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users/user',
        :title    => "RADIUS User: #{params[:userid]}",
        :format   => params[:format],
        :msg      => msg,
        :objects  => {
          'user'    => user
        }
      )
    end

    get '/services/radius/users/:userid/attachments/personal/:basename' do
      attachment(params[:basename]) if params['disposition'] == 'attachment'
      send_file( File.join(
          OnBoard::Service::RADIUS::User::UPLOADS,
          params[:userid],
          'personal',
          params[:basename]
      ) )
    end

  end
end
