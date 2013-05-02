class OnBoard
  module Virtualization
    module QEMU
      module Passthrough
        class PCI
          module VFIOPCI

            System::Command.run 'modprobe vfio-pci', :sudo

            class << self

              def prepare(id)
                # See Documentation/vfio.txt from Linux kernel source
                Dir.foreach "/sys/bus/pci/devices/0000:#{id}/iommu_group/devices" do |file|
                  if file =~ /(\h\h:\h\h\.\h)/
                    ingroup_id = $1
                    if `lspci -n -s #{ingroup_id}` =~ /(\h\h\h\h):(\h\h\h\h)/ 
                      vendor, product = $1, $2
                      System::Command.run \
                          %Q{sh -c 'echo 0000:#{ingroup_id} > /sys/bus/pci/devices/0000:#{ingroup_id}/driver/unbind'},  
                          :sudo
                      System::Command.run \
                          %Q{sh -c 'echo #{vendor} #{product} > /sys/bus/pci/drivers/vfio-pci/new_id'}, 
                          :sudo
                    end
                  end
                end
              end

            end

          end
        end
      end
    end
  end
end
