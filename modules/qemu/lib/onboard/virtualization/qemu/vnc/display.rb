class OnBoard
  module Virtualization
    module QEMU
      module VNC
        class Display

          MAX = 29

          class << self

            def available
              busy = []
              QEMU.get_all.map do |vm|
                begin
                  busy << vm.config['-vnc'].sub(/[^\d]/, '').to_i
                rescue NoMethodError
                end
              end
              return (1..MAX).to_a - busy
            end

          end

        end
      end
    end
  end
end



