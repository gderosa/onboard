require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu/vm/:vmid.:format' do
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      format(
        :module => 'qemu',
        :path => 'virtualization/qemu/vm',
        :format => params[:format],
        :title => "QEMU: #{vm.config['-name']}",
        :objects => {
          :vm => vm,
        }
      )
    end

    put '/virtualization/qemu/vm/:vmid.:format' do
      vm_old = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      vm_new = OnBoard::Virtualization::QEMU::Config.new(
        :http_params  =>  params,
        :uuid         =>  vm_old.uuid
      )
      vm_new.save # replace configuration file

      # Just to be clear ;-)
      vm_new, vm_old = nil

      # Re-read, so the user is able to know whether data has been properly
      # updated
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])

      format(
        :module => 'qemu',
        :path => 'virtualization/qemu/vm',
        :format => params[:format],
        :title => "QEMU: #{vm.config['-name']}",
        :objects => {
          :vm => vm,
        }
      )
    end

    get '/virtualization/qemu/vm/:vmid/screen.:format' do

      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])

      if 
          vm.respond_to? :screendump                  and 
          vm.running?                                 and 
          screendump = vm.screendump(params[:format])

        send_file screendump 

      else

        not_found

      end

    end

  end

end
