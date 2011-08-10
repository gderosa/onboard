require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/terms.:format' do
      documents = []
      msg = handle_errors do
        documents = Service::RADIUS::Terms::Document.get_all
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/terms',
        :title    => "RADIUS/HotSpot users: Usage Policy, Privacy and other regulatory documents",
        :format   => params[:format],
        :objects  => documents,
        :msg      => msg
      )
    end

    post '/services/radius/terms.:format' do
      documents = []
      msg = handle_errors do
        Service::RADIUS::Terms::Document.insert params
        documents = Service::RADIUS::Terms::Document.get_all
      end
      status 201 if msg[:ok] and not msg[:err] 
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/terms',
        :title    => "RADIUS/HotSpot users: Usage Policy, Privacy and other regulatory documents",
        :format   => params[:format],
        :objects  => documents,
        :msg      => msg
      )
    end

    delete '/services/radius/terms/:id.:format' do
      documents = []
      msg = handle_errors do
        Service::RADIUS::Terms::Document.delete params[:id].to_i
      end
      # TODO TODO TODO
    end


  end
end
