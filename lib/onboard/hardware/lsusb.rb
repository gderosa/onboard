class OnBoard
  module Hardware
    class LSUSB
      
      class << self

        include Enumerable

        def all
          each.to_a
        end

        def each
          output_text = `lsusb | grep -v 'Device 001' | grep -v '0000:0000' # exclude hubs`
          Enumerator.new do |yielder|
            parse output_text do |device|
              yielder.yield device
            end
          end
        end

        def parse(text)
          Enumerator.new do |yielder|
            text.each_line do |line|
              # ex.
              #   Bus 001 Device 008: ID 0951:1642 Kingston Technology DT101 G2
              if line =~ /Bus (\d\d\d) Device (\d\d\d): ID ([A-Fa-f\d]{4}):([A-Fa-f\d]{4}) (.*)/
                h = {
                  :bus_id     => $1,
                  :device_id  => $2,
                  :vendor_id  => $3,
                  :product_id => $4,
                  :description => $5
                }
                yielder.yield self.new(h) 
              end
            end
          end
        end

      end

      def initialize(h)
        @data = h
      end

      def method_missing(id, *args, &blk)
        @data[id] 
      end

    end
  end
end
