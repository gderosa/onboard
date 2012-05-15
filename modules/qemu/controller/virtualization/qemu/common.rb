require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu/common.:format' do
      format(
        :module => 'qemu',
        :path => '/virtualization/qemu/common',
        :format => params[:format],
        :objects  => OnBoard::Virtualization::QEMU::Config::Common.get
      )
    end

    put '/virtualization/qemu/common.:format' do
      msg = handle_errors do
        OnBoard::Virtualization::QEMU::Config::Common.set(:http_params => params)
      end
      format(
        :module => 'qemu',
        :path => '/virtualization/qemu/common',
        :format => params[:format],
        :objects  => OnBoard::Virtualization::QEMU::Config::Common.get,
        :msg => msg
      )
    end

  end

end
