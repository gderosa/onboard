class OnBoard
  module Virtualization
    module QEMU
      module Passthrough
        class PCI
          module VFIOPCI

            DRIVER = 'vfio-pci'

            System::Command.send_command "modprobe #{DRIVER}", :sudo

            class << self

              # TODO: lots of logic should be moved to Hardware::LSPCI
              
              def prepare(id)
                # See Documentation/vfio.txt from Linux kernel source
                iommu_group = File.basename File.readlink "/sys/bus/pci/devices/0000:#{id}/iommu_group"
                Dir.foreach "/sys/bus/pci/devices/0000:#{id}/iommu_group/devices" do |file|
                  if file =~ /(\h\h:\h\h\.\h)/
                    ingroup_id = $1
                    if `lspci -n -s #{ingroup_id}` =~ /(\h\h\h\h):(\h\h\h\h)/ 
                      vendor, product = $1, $2
                      System::Command.send_command \
                          %Q{sh -c 'echo 0000:#{ingroup_id} > /sys/bus/pci/devices/0000:#{ingroup_id}/driver/unbind'},  
                          :sudo
                      if Hardware::LSPCI.by_id[ingroup_id][:desc] =~ /PCI Bridge/i
                        System::Command.send_command \
                            %Q{sh -c 'echo 1 > /sys/bus/pci/devices/0000:#{ingroup_id}/rescan'},
                            :sudo
                      else
                        System::Command.send_command \
                            %Q{sh -c 'echo #{vendor} #{product} > /sys/bus/pci/drivers/#{DRIVER}/new_id'}, 
                            :sudo 
                        # Not sure if a rescan might be useful even in this case?
                      end
                    end
                  end
                end
                System::Command.send_command \
                    %Q{chmod 0666 /dev/vfio/vfio},                     :sudo
                System::Command.send_command \
                    %Q{chown #{Process.uid} /dev/vfio/#{iommu_group}}, :sudo
              end

            end

          end
        end
      end
    end
  end
end
