class OnBoard
  module Virtualization
    module QEMU
      module Passthrough
        class USB

          attr_reader :dev
          
          # lsusbdev is a OnBoard::Hardware::LSUSB
          def initialize(lsusbdev)
            @dev = lsusbdev
            @all_vm = QEMU.get_all
          end

          # cnf is an element of vmconfig.opts['-device']
          # where vmconfig is an OnBoard::Virtualization::QEMU::Config object
          def match_config?(cnf)
            return false unless cnf['type'] == 'usb-host' 
            retval = (
              (
                cnf['hostbus'] and cnf['hostbus'] == dev.bus_id and
                (
                  (cnf['hostaddr'] and cnf['hostaddr'] == dev.device_id) or
                  (cnf['hostport'] and cnf['hostport'] == dev.port_id)
                )
              ) or (
                cnf['vendorid']   =~ /(0x)?#{dev.vendor_id}/  and
                cnf['productid']  =~ /(0x)?#{dev.product_id}/
              )
            )
            return retval
          end

          def used_by
            @all_vm.each do |vm|
              next unless vm.config.opts['-device'].respond_to? :each
              vm.config.opts['-device'].each do |cnf|
                return vm if self.match_config? cnf
              end
            end
            nil
          end

        end 
      end
    end
  end
end
