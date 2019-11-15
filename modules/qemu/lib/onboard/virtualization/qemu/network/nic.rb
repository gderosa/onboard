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

              # Assumption: something like:
              #
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
              cmd_output = `#{exe} -nic model=help 2>&1`

              cmd_output.each_line do |l|
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
