require 'facets/hash'
require 'sinatra/base'

require 'onboard/service/radius'
require 'onboard/service/radius/db'

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

    # So you don't get a refresh link in the navbar
    #get '/services/radius/dbdata.:format' do
    #  redirect "/services/radius/resetdb.html" 
    #end

    delete '/services/radius/dbdata.:format' do
      deleted = []
      msg     = handle_errors do
        deleted = Service::RADIUS::Db.reset_data(params)
      end
      unless msg[:err]
        if deleted.length > 0
          msg[:info] = "Data has been deleted!"
        else
          msg[:info] = "RADIUS data have been kept"
        end
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/dbdata',
        :title    => 'RADIUS Database reset',
        :format   => params[:format],
        :formats  => %w{html},
        :objects  => nil,
        :msg      => msg
      )
    end

  end
end
