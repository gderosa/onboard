require 'facets/hash'
require 'facets/string'
require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/pub/services/radius/password-recovery.html' do
      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/password-recovery',
        :title    => i18n.hotspot.password.recovery.you!.capitalize,
        :objects  => {
        }
      )
    end

    post '/pub/services/radius/password-recovery.html' do
      msg = {}
      params['email'].strip!
      if params['email'] =~ /\S+@\S+\.\S+/
        Service::RADIUS::Passwd.recovery :email => params['email']
        msg = {
          :ok   => true,
          :info => t.hotspot.password.recovery.message
        }
      else
        status 409
        msg = {
          :ok   => false,
          :err  => t.email.invalid_address.capitalize + '.'
        }
      end
      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/password-recovery',
        :title    => i18n.hotspot.password.recovery.you!.capitalize,
        :objects  => {},
        :msg      => msg
      )
    end

  end
end
