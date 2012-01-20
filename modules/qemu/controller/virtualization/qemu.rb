require 'sinatra/base'

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
      same_as_GET
    end

  end

end
