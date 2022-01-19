class OnBoard
  module Network
    class Interface
      class MAC

        def self.valid_address?(str)
          return false unless str =~ /^\s*[\da-f][\da-f]:[\da-f][\da-f]:[\da-f][\da-f]:[\da-f][\da-f]:[\da-f][\da-f]:[\da-f][\da-f]\s*$/i
          return false if
              ["00:00:00:00:00:00", "ff:ff:ff:ff:ff:ff"].include? str
          return true
        end

        attr_reader :string, :raw

        def initialize(arg)
          case arg
          when String
            @string = arg
            set_raw_from_string
          when Integer
            @raw = arg
            set_string_from_raw
          else
            raise TypeError,
              "Initialization argument must be a String or an integer: got #{args.class.name}"
          end
        end

        def valid?
          if ["00:00:00:00:00:00", "ff:ff:ff:ff:ff:ff"].include? @string
            return false
          else
            return true
          end
        end

        def ==(other)
          @raw == other.raw
        end

        def <=>(other)
          @raw <=> other.raw
        end

        def data
          @string
        end

        def to_s
          data
        end

        def to_json(*a); to_s.to_json(*a); end
        def to_yaml(*a); to_s.to_yaml(*a); end

        private

        def set_raw_from_string
          s = @string.gsub(/[^\da-f]/i, "")
          @raw = s.to_i(16)
        end

        def set_string_from_raw
          s = raw.to_s(16)
          s =~ # 6*2 hexadecimal digits
            /([\da-f]{2})([\da-f]{2})([\da-f]{2})([\da-f]{2})([\da-f]{2})([\da-f]{2})/
          @string = "#$1:#$2:#$3:#$4:#$5:#$6"
        end

      end
    end
  end
end
