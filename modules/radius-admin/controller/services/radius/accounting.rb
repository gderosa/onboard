require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/accounting.:format' do
      use_pagination_defaults
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/accounting',
        :title    => 'RADIUS Accounting',
        :format   => params[:format],
        :objects  => Service::RADIUS::Accounting.get(params)           
      )
    end

  end
end
