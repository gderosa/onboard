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
      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/password-recovery',
        :title    => i18n.hotspot.password.recovery.you!.capitalize,
        :objects  => {
        }
      )
    end

  end
end
