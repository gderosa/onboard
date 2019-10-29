require 'sinatra/base'

require 'onboard/virtualization/qemu'

class OnBoard

  class Controller < Sinatra::Base

    before do
      if request.path_info =~ /^\/virtualization\/qemu/
        Virtualization::QEMU.cleanup
      end
    end

    get '/virtualization/qemu.:format' do
      format(
        :module   => 'qemu',
        :path     => '/virtualization/qemu',
        :format   => params[:format],
        :objects  => OnBoard::Virtualization::QEMU.get_all,
        :title    => 'QEMU Virtualization'
      )
    end

    post '/virtualization/qemu.:format' do
      msg = handle_errors do
        params['disk'] ||= []
        #
        # normalize
        if params['disk'].respond_to? :each_pair
          ary = []
          params['disk'].each_pair do |k,v|
            ary[k.to_i] = v
          end
          params['disk'] = ary
        end
        #
        params['disk'].each_with_index do |hd, idx|
          if hd['qemu-img'] and hd['qemu-img']['create']
            hd.update( {
              'idx'     => idx,
              'vmname'  => params['name'],
            } )
            created_disk_image =
                OnBoard::Virtualization::QEMU::Img.create(hd)
            params['disk'][idx]['file'] = created_disk_image
            params['disk'][idx]['path'] = \
                OnBoard::Virtualization::QEMU::Img.relative_path created_disk_image
          end

          # If image file comes from form text input / browsing (not creation)
          if hd['path'] =~ /\S/
            params['disk'][idx]['file'] ||=
                OnBoard::Virtualization::QEMU::Img.absolute_path hd['path']
          else
            params['disk'][idx]['file'] = nil # explicit is better than implicit :-)
          end
        end
        #
        vm_new = OnBoard::Virtualization::QEMU::Config.new(
          :http_params  =>  params,
        )
        vm_new.save
      end

      format(
        :module   => 'qemu',
        :path     => '/virtualization/qemu',
        :format   => params[:format],
        :objects  => OnBoard::Virtualization::QEMU.get_all,
        :msg      => msg,
        :title    => 'QEMU Virtualization'
      )
    end

    put '/virtualization/qemu.:format' do
      msg = handle_errors do
        OnBoard::Virtualization::QEMU.manage(:http_params => params)
        OnBoard::Virtualization::QEMU.cleanup
      end
      sleep 0.2 # diiirty, but avoid querying dead Monitors...
      format(
        :module   => 'qemu',
        :path     => '/virtualization/qemu',
        :format   => params[:format],
        :objects  => OnBoard::Virtualization::QEMU.get_all,
        :msg      => msg,
        :title    => 'QEMU Virtualization'
      )
    end

  end

end
