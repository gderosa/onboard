require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu/vm/:vmid/bits/run.html' do
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      if vm
        partial(
          :module => 'qemu',
          :path   => 'virtualization/qemu/vm/_run',
          :locals => {
            :vm     => vm,
          },
        )
      else
        not_found
      end
    end

  end
end
