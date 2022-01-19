require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu/vm/:vmid/bits/status' do
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      if vm
        begin
          vm.status :raise => true
        rescue Timeout::Error, Errno::ECONNRESET, Errno::ECONNREFUSED
          halt 500, $!.to_s # JS will handle this, not updating innerHTML
        end
      else
        @override_not_found = true
        halt 404, '[Not Found]'
      end
    end

  end
end
