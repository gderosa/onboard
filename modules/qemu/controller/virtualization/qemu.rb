require 'sinatra/base'

require 'onboard/v12n/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu.:format' do
      format(
        :module => 'qemu',
        :path => '/virtualization/qemu',
        :format => params[:format],
        :objects  => {}
      )
    end

    post '/virtualization/qemu.:format' do
      OnBoard::V12n::QEMU::Config.new(:http_params=>params).save()
      same_as_GET
    end

  end

end
