class OnBoard
  module Hardware
    class LSUSB

      LINE_REGEX  = /Bus (\d\d\d) Device (\d\d\d): ID ([A-Fa-f\d]{4}):([A-Fa-f\d]{4}) (.*)/
      HUB_REGEX   = /hub\s*$/i

      class Enumerator < ::Enumerator
        # Lazily convert into Array
        def method_missing(id, *args, &blk)
          to_a.send id, *args, &blk
        end
      end
      
      class << self

        def method_missing(id, *args, &blk)
          all.send id, *args, &blk
        end

        def all
          output_text = `lsusb`
          parse output_text 
        end
        alias devices all

        def parse(text, *opts)
          Enumerator.new do |yielder|
            text.each_line do |line|
              # ex.
              #   Bus 001 Device 008: ID 0951:1642 Kingston Technology DT101 G2
              unless opts.include? :all
                next if line =~ HUB_REGEX
              end
              if line =~ LINE_REGEX
                h = {
                  :bus_id       => $1,
                  :device_id    => $2,
                  :vendor_id    => $3,
                  :product_id   => $4,
                  :description  => $5,
                  :full_line    => line.strip,
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
