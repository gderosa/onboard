class OnBoard
  module Hardware
    class LSUSB

      class SysFSData

        BASEDIR = '/sys/bus/usb/devices'

        def initialize
          @data = []
          return unless Dir.exists? BASEDIR  # Some VMs simply do not have USB at all...
          Dir.foreach BASEDIR do |subdir|
            if subdir =~ /^(\d+)-(\d+(.\d+)?)$/
              bus, port = $1, $2
              dev = File.read("#{BASEDIR}/#{subdir}/devnum").strip
              @data << {
                :bus_id     => bus,
                :device_id  => dev,
                :port_id    => port,
              }
            end
          end
        end

        def method_missing(id, *args, &blk)
          @data.send id, *args, &blk
        end

      end

      LINE_REGEX  = /Bus (\d\d\d) Device (\d\d\d): ID ([A-Fa-f\d]{4}):([A-Fa-f\d]{4}) (.*)/
      HUB_REGEX   = /hub\s*$/i

      # # NOTE/(TODO?): does all this sophisticated "laziness" make any sense?
      # # We'll have to (eagerly) scan /sys/bus/usb to find physical ports...

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
          @sysfs_data = SysFSData.new
          output_text = `lsusb`
          parse output_text
        end
        alias devices all

        def parse(text, *opts)
          opt_h = opts.find{|o| o.is_a? Hash}

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
                next if h[:vendor_id] =~ /^[\s0]*$/
                sysfs_entry = @sysfs_data.find do |entry|
                  # NOTE: String#to_i has been "smartly" overwritten
                  # in lib/extensions, so a String like "011" would be interpreted
                  # as octal :-/
                  entry[:bus_id].to_i     == h[:bus_id].to_i    and
                  entry[:device_id].to_i  == h[:device_id].to_i
                end
                h[:port_id] = sysfs_entry[:port_id] if sysfs_entry
                yielder.yield self.new(h)
              end
            end
          end
        end

      end

      attr_reader :vendor, :model

      def initialize(h)
        @data = h
        if @data[:vendor_id] and @data[:model_id]
          `lsusb -d #{@data[:vendor_id]}:#{@data[:model_id]} -v`.each_line do |line|
            if line =~ /^\s+idVendor\s+0x#{@data[:vendor_id]}\s+(.*)/
              @vendor = $1
            elsif line =~ /^\s+idProduct\s+0x#{@data[:model_id]}\s+(.*)/
              @model = $1
            end
          end
        end
      end

      def method_missing(id, *args, &blk)
        @data[id]
      end

    end
  end
end
