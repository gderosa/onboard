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

    get '/services/radius/terms/:id.:format' do |id, fmt|
      document = nil
      msg = handle_errors do
        document = Service::RADIUS::Terms::Document.get id.to_i
      end
      not_found unless document
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/terms/document',
        :title    => "RADIUS/HotSpot users: Policy document",
        :format   => fmt,
        :objects  => document,
        :msg      => msg
      )
    end

    put '/services/radius/terms/:id.:format' do |id, fmt|
      document = nil
      msg = handle_errors do
        document = Service::RADIUS::Terms::Document.get id.to_i
      end
      not_found unless document
      msg = handle_errors do
        document = Service::RADIUS::Terms::Document.update id.to_i, params
      end
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/terms/document',
        :title    => "RADIUS/HotSpot users: Policy document",
        :format   => fmt,
        :objects  => document,
        :msg      => msg
      )
    end

    delete '/services/radius/terms/:id.:format' do
      msg = handle_errors do
        Service::RADIUS::Terms::Document.delete params[:id].to_i
        redirect "/services/radius/terms.#{params[:format]}" 
      end
      # errors
      format(
        :path     => '/generic',
        :title    => "RADIUS/HotSpot users: Usage Policy, Privacy and other regulatory documents",
        :format   => params[:format],
        :msg      => msg
      )
    end

  end
end
