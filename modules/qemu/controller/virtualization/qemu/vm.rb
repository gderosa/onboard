require 'sinatra/base'

require 'onboard/extensions/array'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    get '/virtualization/qemu/vm/:vmid.:format' do
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      not_found unless vm
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
      
      msg = handle_errors do

        # Edit static configuration
        if params['name'] 
        
          # Possibly create a new image (the old one will be renamed in .old, see
          # Img.create implementation in 
          # /modules/qemu/lib/onboard/virtualization/qemu/img.rb ) 
          created_disk_image =
              OnBoard::Virtualization::QEMU::Img.create(:http_params => params)
          if created_disk_image
            params['disk'] = created_disk_image
          end

          vm_new = OnBoard::Virtualization::QEMU::Config.new(
            :http_params  =>  params,
            :uuid         =>  vm_old.uuid
          )

          vm_new.save # replace configuration file
        end

        # Action buttons / runtime
        if params.keys.include_any_of?(%w{
                start start_paused stop pause quit powerdown resume delete 
                snapshot_take snapshot_apply snapshot_delete snapshot_schedule
        }) 
                # Yup, deleting with a PUT is unRESTful... :-P
          OnBoard::Virtualization::QEMU.manage(:http_params => params)
        end

        OnBoard::Virtualization::QEMU.cleanup
      end

      # Just to be clear ;-)
      vm_new, vm_old = nil

      # Re-read, so the user is able to know whether data has been properly
      # updated
      vm = OnBoard::Virtualization::QEMU.find(:vmid => params[:vmid])
      redirect "/virtualization/qemu.#{params[:format]}" if 
          params['delete'] and not vm
      status 202 if msg[:ok] and params.keys.include_any_of? %w{
          snapshot_take snapshot_apply snapshot_delete } 
      format(
        :module => 'qemu',
        :path => 'virtualization/qemu/vm',
        :format => params[:format],
        :title => "QEMU: #{vm.config['-name']}",
        :objects => {
          :vm => vm,
        },
        :msg => msg
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
