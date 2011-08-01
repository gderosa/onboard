require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/signup.:format' do
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/signup',
        :title    => "End-user sign up",
        :format   => params[:format],
      )
    end

    put '/services/radius/signup.:format' do
      Service::RADIUS::Signup.update_config params
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/signup',
        :title    => "End-user sign up",
        :format   => params[:format],
      )
    end

  end
end
