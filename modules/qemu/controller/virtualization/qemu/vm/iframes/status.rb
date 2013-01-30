require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu/vm/:vmid/iframes/status' do
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      if vm 
        vm.status
      else
        @override_not_found = true
        halt 404, '[Not Found]'
      end
    end

  end
end
