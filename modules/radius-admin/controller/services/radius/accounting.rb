require 'sequel'
require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/accounting.:format' do
      use_pagination_defaults
      objects = Service::RADIUS::Accounting.get(params)
      msg = {:err => Service::RADIUS::Db.format_error_msg(objects['error'])}
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
