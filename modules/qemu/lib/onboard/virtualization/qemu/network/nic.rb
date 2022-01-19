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
              model_list = []

              cmd_output = `#{exe} -nographic -nic model=help 2>&1`

              cmd_output.each_line do |l|
                # QEMU3 will output like:
                # qemu: Supported NIC models: e1000,e1000-82544gc,e1000-82545em,e1000e,i82550,i82551,i82557a,i82557b,i82557c,i82558a,i82558b,i82559a,i82559b,i82559c,i82559er,i82562,i82801,ne2k_pci,pcnet,rocker,rtl8139,virtio-net-pci,vmxnet3
                if l =~ /models:\s+([^:]+)/
                  model_list = $1.split(/,\s*/)
                  if model_list.size > 1  # only 1 model means probably a spurious line
                    return model_list
                  end
                end
                # QEMU4 will output like:
                # Supported NIC models:
                # e1000
                # e1000-82544gc
                # e1000-82545em
                # e1000e
                # i82550
                # i82551
                # [...]
                # virtio-net-pci
                # virtio-net-pci-non-transitional
                # virtio-net-pci-transitional
                # vmxnet3
                next if l =~ /\S\s+\S/
                l.strip!
                model_list << l
              end
              return model_list
            end

          end

        end
      end
    end
  end
end
