require 'onboard/extensions/array'
require 'onboard/extensions/nilclass'

class OnBoard
  module Virtualization
    module QEMU
      module Network
        class NIC

          autoload :MAC, 'onboard/virtualization/qemu/network/nic/mac'

          class << self

            def models(*opts)
              @models = get_models if @models.none? or opts.include_any_of? [:reset, :reset_list, :rescan]
              return @models
            end

            def get_models
              exe = QEMU::Config::Common.get['exe']
              # Assumption: something like
              #   qemu: Supported NIC models: ne2k_pci,i82551,i82557b,i82559er,rtl8139,e1000,pcnet,virtio
              cmd_output = `#{exe} -net nic,model=? 2>&1`
              if cmd_output =~ /NIC models: ([^\s\n]+)/mi
                model_list = $1
                model_list.split(',')
              else
                []
              end
            end

          end

        end
      end
    end
  end
end
