require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/accounting.:format' do
      use_pagination_defaults
      objects = {
        'rows'        => [],
        'total_items' => 0,
        'page'        => 1,
        'per_page'    => params[:per_page]
      }
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
