require 'sinatra/base'

class OnBoard

  class Controller < Sinatra::Base

    get '/network/openvpn/client-side-configuration.html' do
      format(
        :module => 'openvpn',
        :path => '/network/openvpn/client-side-configuration',
        :format => 'html',
        #:objects  => vpns,
        :title  => 'Cient-side configuration Wizard'
      )
    end

  end

end
