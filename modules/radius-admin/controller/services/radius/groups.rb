require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/groups.:format' do
      use_pagination_defaults
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/groups',
        :format   => params[:format],
        :objects  => Service::RADIUS::Group.get(params)
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
          'group'   => group,
          'members' => member_info
        },
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
          'group'     => group,
          'members'   => member_info
        }
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
