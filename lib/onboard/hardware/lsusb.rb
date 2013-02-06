class OnBoard
  module Hardware
    class LSUSB
      
      class < self
        def all
          `lsusb | grep -v 'Device 001' # exclude hubs`.each_line do |line|
            p line
          end
        end
      end

    end
  end
end
