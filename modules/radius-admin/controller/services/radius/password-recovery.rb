require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/password-recovery.:format' do
      config = nil
      handle_errors do
        config = Service::RADIUS::Passwd::Recovery::Config.get
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/password-recovery',
        :title    => 'Password recovery/reset configuration',
        :format   => params[:format],
        :objects  => config,
        :msg      => @msg
      )
    end

    put '/services/radius/password-recovery.:format' do
      config = nil
      handle_errors do
        config = Service::RADIUS::Passwd::Recovery::Config.new params['config']
        config.save
      end
      same_as_get
    end

  end
end
