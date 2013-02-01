require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu/vm/:vmid/bits/buttons/power.html' do
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      if vm
        partial(
          :module => 'qemu',
          :path   => 'virtualization/qemu/vm/buttons/_power',
          :locals => {
            :vm     => vm,
          }
        )
      else
        @override_not_found = true
        halt 404, '[Not Found]'
      end
    end

  end
end
