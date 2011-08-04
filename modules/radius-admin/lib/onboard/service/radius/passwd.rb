require 'onboard/extensions/string'
require 'onboard/extensions/digest'

autoload :Base64, 'base64'

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

        CHECK = {
          'Cleartext-Password'  => 
              lambda{|s, encr| s == encr},

          'Crypt-Password'      => 
              lambda do |s, encr| 
                # salt is at the beginning, as opposed to MD5 and SHA1
                salt = encr[0..1]
                salted = s.crypt(salt)
                salted == encr
              end, 

          'MD5-Password'        => 
              lambda{|s, encr| Digest::MD5.hexdigest(s) == encr},

          'SMD5-Password'       => 
              lambda do |s, encr| 
                salt = encr.hex2bin[Digest::MD5.digest_length..-1] 
                salted = Digest::MD5.salted_hexdigest(s, salt)
                salted == encr
              end,

          'SHA1-Password'       => 
              lambda{|s, encr| Digest::SHA1.base64digest(s) == encr},

          'SSHA1-Password'      => 
              lambda do |s, encr|
                salt = Base64.decode64(encr)[Digest::SHA1.digest_length..-1]
                salted = Digest::SHA1.salted_base64digest(s, salt)
                salted == encr
              end,
        }

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

        def check(encrypted)
          return nil unless (@cleartext && encrypted)
          check_type
          CHECK[@type].call(@cleartext, encrypted) 
        end

        def check_type
          raise UnknownType, "Unknown type #{@type.inspect}; allowed passwd types are: #{TYPES.join(', ')}" unless
            TYPES.include? @type
        end

      end
    end
  end
end
