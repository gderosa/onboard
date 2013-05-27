class OnBoard
  module Virtualization
    module QEMU
      module Passthrough
        class PCI

          autoload :PCIAssign, 'onboard/virtualization/qemu/passthrough/pci/pci-assign'
          autoload :VFIOPCI,   'onboard/virtualization/qemu/passthrough/pci/vfio-pci'

          DRIVERS       = %w{pci-assign vfio-pci}
          TYPES         = DRIVERS
          EXCLUDE_LSPCI_DESCS = 
              /host bridge|pci bridge|isa bridge|ide interface|usb controller|smbus|communication controller/i
          EXCLUDE_DESCS = EXCLUDE_LSPCI_DESCS # Compat

          def initialize(pci_id)
            @pci_id = pci_id
            @all_vm = QEMU.get_all
          end

          def used_by
            @all_vm.each do |vm|
              next unless vm.config.opts['-device'].respond_to? :each
              vm.config.opts['-device'].each do |device|
                next unless DRIVERS.include? device['driver'] or TYPES.include? device['type']
                return vm if device['host'] == @pci_id
              end
            end
            nil
          end

          class << self

            def prepare(h)
              type = h['driver'] || h['type']
              case type
              when 'pci-assign'
                # http://www.linux-kvm.org/page/How_to_assign_devices_with_VT-d_in_KVM
                PCIAssign.prepare h['host']
              when /^vfio/ # vfio-pci
                # https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/vfio.txt#n116
                VFIOPCI.prepare h['host']
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
