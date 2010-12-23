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

    post '/services/radius/groups.:format' do
      use_pagination_defaults
      msg = handle_errors{Service::RADIUS::Group.insert(params)} 
      if msg[:ok] and not msg[:err]
        name  = params['check']['Group-Name']
        group = Service::RADIUS::Group.new(name)  
        msg   = handle_errors{group.update_reply_attributes(params)} 
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/groups',
        :format   => params[:format],
        :objects  => Service::RADIUS::Group.get(params),
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

    get '/services/radius/groups/:groupid.:format' do
      use_pagination_defaults # member users list
      group = Service::RADIUS::Group.new(params[:groupid])
      group.retrieve_attributes_from_db
      not_found unless group.found?
      member_info = group.get_members(params)
      members = member_info['users']
      members.each do |member|
        member.retrieve_attributes_from_db if 
            !member.check or member.check.length == 0
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/groups/group',
        :format   => params[:format],
        :objects  => {
          'conf'    => Service::RADIUS.conf,
          'group'   => group,
          'members' => member_info
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
          'conf'    => Service::RADIUS.conf,
          'user'    => user
        }
      )
    end

    put '/services/radius/groups/:groupid.:format' do
      use_pagination_defaults
      group = Service::RADIUS::Group.new(params[:groupid])
      group.retrieve_attributes_from_db
      not_found unless group.found?
      msg = handle_errors do 
        group.update(params)
        group.retrieve_attributes_from_db
      end
      unless group.found?
        msg[:warn] = "User has no longer any attribute!"
      end

      member_info = group.get_members(params)
      members = member_info['users']
      members.each do |member|
        member.retrieve_attributes_from_db if 
            !member.check or member.check.length == 0
      end
     
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/groups/group',
        :format   => params[:format],
        :msg      => msg,
        :objects  => {
          'conf'    => Service::RADIUS.conf,
          'group'     => group,
          'members'   => member_info
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

    delete '/services/radius/groups/:groupid.:format' do
      group = Service::RADIUS::Group.new params[:groupid] 
      if group.found?
        if params['confirm'] =~ /on|yes|true|1/
          group.delete!
          status 303 # HTTP See Other
          headers 'Location' => "/services/radius/groups.#{params[:format]}" 
        else
          status 204 # HTTP No Content # TODO: is this the right code?
        end
      else
        not_found
      end
    end

  end
end
