require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu.:format' do
      format(
        :module => 'qemu',
        :path => '/virtualization/qemu',
        :format => params[:format],
        :objects  => OnBoard::Virtualization::QEMU.get_all
      )
    end

    post '/virtualization/qemu.:format' do
      pp params
      msg = handle_errors do
        OnBoard::Virtualization::QEMU::Img.create(:http_params=>params) 
        #OnBoard::Virtualization::QEMU::Config.new(:http_params=>params).save()
      end
      format(
        :module => 'qemu',
        :path => '/virtualization/qemu',
        :format => params[:format],
        :objects  => OnBoard::V12n::QEMU.get_all,
        :msg => msg
      )
    end

  end

end
