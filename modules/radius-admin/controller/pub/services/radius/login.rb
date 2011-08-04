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
        :title    => "RADIUS End User Account Management",
      )
    end

    # This is un-ReSTful: HTTP Authentication should be used instead of 
    # sessions; but this is unconvenient to end users who expect a "logout" 
    # link somewhere
    post '/pub/services/radius/login.html' do
      session[:raduser] = params['raduser']
      session[:radpass] = params['radpass']
      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/login',
        :title    => "RADIUS End User Account Management",
      )
    end

    get '/pub/services/radius/logout.html' do
      session[:raduser] = nil
      session[:radpass] = nil
      redirect '/pub/services/radius/login.html'
    end

  end
end
