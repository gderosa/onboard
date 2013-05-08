class OnBoard
  module Virtualization
    module QEMU
      module Passthrough
        class USB

          attr_reader :dev
          
          def initialize(lsusbdev)
            @usb = lsusbdev # OnBoard::Hardware::LSUSB
            @all_vm = QEMU.get_all
          end

          def used_by
            @all_vm.each do |vm|
              next unless vm.config.opts['-device'].respond_to? :each
              vm.config.opts['-device'].each do |cnf|
                next unless device['type'] == 'usb-host'
                return vm if (
                  cnf['hostbus'] and cnf['hostbus'] == dev.bus_id and
                  (
                    (cnf['hostaddr'] and cnf['hostaddr'] == dev.device_id) or
                    (cnf['hostport'] and cnf['hostport'] == dev.port_id)
                  )
                ) or (
                  cnf['vendorid']   =~ /(0x)?#{dev.vendor_id}/  and
                  cnf['productid']  =~ /(0x)?#{dev.product_id}/
                )
              end
            end
            nil
          end

        end 
      end
    end
  end
end
