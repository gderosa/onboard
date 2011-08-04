require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/pub/services/radius/users/:userid.:format' do
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

    put '/pub/services/radius/users/:userid.:format' do
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

    get '/pub/services/radius/users/:userid/attachments/personal/:basename' do
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
