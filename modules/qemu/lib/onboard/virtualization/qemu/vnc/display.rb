class OnBoard
  module Virtualization
    module QEMU
      module VNC
        class Display

          class << self

            def available
              busy = QEMU.get_all.map do |vm|
                vm.config['-vnc'].sub(/[^\d]/, '').to_i 
              end
              return (1..31).to_a - busy 
            end

          end

        end
      end
    end
  end
end

        

