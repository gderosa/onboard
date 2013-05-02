class OnBoard
  module Virtualization
    module QEMU
      module Passthrough
        module PCI

          EXCLUDE_DESCS = 
              /host bridge|pci bridge|isa bridge|ide interface|usb controller|smbus|communication controller/i

        end
      end
    end
  end
end
