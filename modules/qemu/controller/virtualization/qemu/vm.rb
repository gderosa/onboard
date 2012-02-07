require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu/vm/:vmid/screen.:format' do
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      if vm.respond_to? :screendump and vm.running?
        send_file vm.screendump(params[:format]) 
      else
        not_found
      end
    end

  end

end
