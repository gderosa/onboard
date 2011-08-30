require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    enable :sessions

    get '/pub/services/radius/login.html' do
      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/login',
        :title    => i18n.hotspot.account.management,
      )
    end

    # This is un-ReSTful: HTTP Authentication should be used instead of 
    # sessions; but this is unconvenient to end users who expect a "logout" 
    # link somewhere
    post '/pub/services/radius/login.html' do
      session[:raduser] = params['raduser']
      session[:radpass] = params['radpass']

      user = Service::RADIUS::User.new(params['raduser'])
      msg = {}
      msg = handle_errors do
        user.retrieve_attributes_from_db
        #not_found unless user.found?
      end

      if user.found? and user.check_password session[:radpass]
        redirect "/pub/services/radius/users/#{user.name}.html"
      else
        msg[:ok] = false
        msg[:err] = 'Login Failed'
        status 403 # Forbidden
      end
      
      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/login',
        :title    => "RADIUS End User Account Management",
        :msg      => msg
      )
    end

    get '/pub/services/radius/logout.html' do
      session[:raduser] = nil
      session[:radpass] = nil
      redirect '/pub/services/radius/login.html'
    end

  end
end
