require 'sinatra/base'

require 'onboard/v12n/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu.:format' do
      format(
        :module => 'qemu',
        :path => '/virtualization/qemu',
        :format => params[:format],
        :objects  => OnBoard::V12n::QEMU.get_all
      )
    end

    post '/virtualization/qemu.:format' do
      msg = handle_errors do
        OnBoard::V12n::QEMU::Config.new(:http_params=>params).save()
        # raise OnBoard::Confict, 'aaargh!!'
      end
      format(
        :module => 'qemu',
        :path => '/virtualization/qemu',
        :format => params[:format],
        :objects  => OnBoard::V12n::QEMU.get_all,
        :msg => msg.merge(:info => "I Feel Happy")
      )
    end

  end

end
