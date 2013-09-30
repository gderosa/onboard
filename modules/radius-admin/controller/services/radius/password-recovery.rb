require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/password-recovery.:format' do
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/password-recovery',
        :title    => 'Password recovery / reset configuration',
        :format   => params[:format],
        :objects  => {},
        :msg      => {}
      )
    end

  end
end
