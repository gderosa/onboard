require 'facets/hash'
require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/resetdb.html' do # no json/yaml here
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/resetdb',
        :title    => 'RADIUS Database reset',
        :format   => 'html',
        :formats  => %w{html}
      )
    end

  end
end
