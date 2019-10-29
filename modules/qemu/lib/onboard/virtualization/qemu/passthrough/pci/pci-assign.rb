require 'onboard/system/command'

class OnBoard
  module Virtualization
    module QEMU
      module Passthrough
        class PCI
          module PCIAssign

            System::Command.run 'modprobe pci_stub', :sudo

            class << self

              def prepare(id)
                # http://www.linux-kvm.org/page/How_to_assign_devices_with_VT-d_in_KVM
                if `lspci -n -s #{id}` =~ /(\h\h\h\h):(\h\h\h\h)/ # TODO: move this into LSPCI library?
                  vendor, product = $1, $2
                  System::Command.run \
                      %Q{sh -c 'echo "#{vendor} #{product}" > /sys/bus/pci/drivers/pci-stub/new_id'}, :sudo
                  System::Command.run \
                      %Q{sh -c 'echo 0000:#{id} > /sys/bus/pci/devices/0000:#{id}/driver/unbind'},    :sudo
                  System::Command.run \
                      %Q{sh -c 'echo 0000:#{id} > /sys/bus/pci/drivers/pci-stub/bind'},               :sudo
                else
                  raise RuntimeError, "PCI device ``#{id}'' not found"
                end
              end

            end

          end
        end
      end
    end
  end
end
