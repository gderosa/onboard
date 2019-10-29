require 'sequel'
require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/accounting.:format' do
      use_pagination_defaults
      msg = objects = {}
      msg = handle_errors do
        objects = Service::RADIUS::Accounting.get(params)
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/accounting',
        :title    => 'RADIUS Accounting',
        :format   => params[:format],
        :objects  => objects,
        :msg      => msg
      )
    end

  end
end
