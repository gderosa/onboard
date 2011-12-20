require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/pub/services/radius/terms/:id.html' do |id|
      msg = {:ok => true}
      begin
        document = Service::RADIUS::Terms::Document.get id
        not_found unless document
      rescue Sequel::Error
        status 500
        msg = {:ok => false, :err => $!} 
      end
      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/terms/document',
        :locals   => {:document => document},
        :title    => document[:name],
        :msg      => msg
      )
    end

  end
end
