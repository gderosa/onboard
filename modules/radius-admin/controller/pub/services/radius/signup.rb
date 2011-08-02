require 'facets/hash'

require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/pub/services/radius/signup.html' do
      conf = Service::RADIUS::Signup.get_config
      if conf['enable'] 
        format(
          :module   => 'radius-admin',
          :path     => '/pub/services/radius/signup',
        )
      else
        status 403 # Forbidden
        format(
          :module   => 'radius-admin',
          :path     => '/pub/services/radius/signup_disabled',
        )
      end
    end

    post '/pub/services/radius/signup.html' do
      name  = params['check']['User-Name']
      user  = Service::RADIUS::User.new(name) # blank slate
      msg = handle_errors do
        h = Service::RADIUS::Signup.get_config.deep_merge(params)
        Service::RADIUS::Check.insert(h)
        user.update_reply_attributes(h) 
        user.update_personal_data(h)
        user.upload_attachments(h) 
      end
      if msg[:ok] and not msg[:err] 
        status 201 # Created
        #msg[:info] = %Q{User <a class="created" href="users/#{user.name}.#{params[:format]}">#{user.name}</a> has been created!}
        msg[:info] = %Q{User has been created!}
      end

      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/signup',
        :msg      => msg
      )

    end
  end
end
