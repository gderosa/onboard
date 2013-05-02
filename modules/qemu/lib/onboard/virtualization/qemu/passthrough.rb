class OnBoard
  module Virtualization
    module QEMU
      module Passthrough

        autoload :PCI,      'onboard/virtualization/qemu/passthrough/pci'
        autoload :USB,      'onboard/virtualization/qemu/passthrough/usb'

      end
    end
  end
end
