class OnBoard
  module Virtualization
    module QEMU
      module Network
        class NIC
        
          class << self

            def models
              @@models ||= get_models
            end

            def get_models
              exe = QEMU::Config::Common.get['exe']
              # Assumption: something like
              #   qemu: Supported NIC models: ne2k_pci,i82551,i82557b,i82559er,rtl8139,e1000,pcnet,virtio
              `#{exe} -net nic,model=? 2>&1` =~ /(\S+)\s?$/
              $1.split(',') 
            end

          end

        end
      end
    end
  end
end
