require 'onboard/extensions/string'
require 'onboard/extensions/digest'

class OnBoard
  module Service
    module RADIUS
      class Passwd

        ENCRYPT = {
          'Cleartext-Password'  => 
              lambda{|s| s},

          'Crypt-Password'      => 
              lambda{|s| s.salted_crypt}, # autogenerate a random salt

          'MD5-Password'        => 
              lambda{|s| Digest::MD5.hexdigest s},

          'SMD5-Password'       => 
              lambda{|s| Digest::MD5.salted_hexdigest s},

          'SHA1-Password'       => 
              lambda{|s| Digest::SHA1.base64digest s},

          'SSHA1-Password'      => 
              lambda{|s| Digest::SHA1.salted_base64digest s},
        }

        TYPES   = ENCRYPT.keys

        class UnknownType < ArgumentError; end

        def initialize(h)
          @type       = h[:type]
          @cleartext  = h[:cleartext]
          check_type
        end

        def compute
          check_type
          ENCRYPT[@type].call(@cleartext)
        end
        alias to_s compute

        def check_type
          raise UnknownType, "Unknown type #{@type.inspect}; allowed passwd types are: #{TYPES.join(', ')}" unless
            TYPES.include? @type
        end

      end
    end
  end
end
