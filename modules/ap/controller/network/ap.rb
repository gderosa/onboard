require 'sinatra/base'

require 'onboard/network/ap'

class OnBoard
  class Controller < Sinatra::Base

    get '/network/ap.:format' do
      format(
        :module => 'ap',
        :path => '/network/ap',
        :format => params[:format],
        :objects  => [],
        :title => "Wireless Access Point"
      )
    end

  end
end

