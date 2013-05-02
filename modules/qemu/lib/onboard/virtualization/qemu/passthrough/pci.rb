class OnBoard
  module Virtualization
    module QEMU
      module Passthrough
        module PCI

          autoload :PCIAssign, 'onboard/virtualization/qemu/passthrough/pci/pci-assign'
          autoload :VFIOPCI,   'onboard/virtualization/qemu/passthrough/pci/vfio-pci'

          EXCLUDE_DESCS = 
              /host bridge|pci bridge|isa bridge|ide interface|usb controller|smbus|communication controller/i

          class << self

            def prepare(h)
              case h['type']
              when 'pci-assign'
                # http://www.linux-kvm.org/page/How_to_assign_devices_with_VT-d_in_KVM
                PCIAssign.prepare h['host']
              when /^vfio/ # vfio-pci
                warn 'Not Implemented'
              else
                raise ArgumentError, "Unknown PCI passthrough type ``#{type}''"
              end
            end

          end

        end
      end
    end
  end
end
