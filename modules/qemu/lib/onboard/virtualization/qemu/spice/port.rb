class OnBoard
  module Virtualization
    module QEMU
      module SPICE
        class Port

          MIN = 5931
          MAX = 5959

          class << self

            def available
              busy = []
              QEMU.get_all.map do |vm|
                begin
                  busy << vm.config['-spice']['port'].to_i
                rescue NoMethodError
                end
              end
              return (MIN..MAX).to_a - busy
            end

          end

        end
      end
    end
  end
end



