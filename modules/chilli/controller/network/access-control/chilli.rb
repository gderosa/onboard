require 'sinatra/base'

require 'onboard/network/access-control/chilli'

class OnBoard

  class Controller < Sinatra::Base

    get '/network/access-control/chilli.:format' do
      all = OnBoard::Network::AccessControl::Chilli.getAll()
      format(
        :module => 'chilli',
        :path => '/network/access-control/chilli',
        :format => params[:format],
        :objects  => all
      )
    end
    
  end

end
