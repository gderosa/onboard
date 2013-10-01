require 'onboard/extensions/string'
require 'onboard/extensions/digest'

require 'onboard/service/mail'
require 'onboard/service/mail/smtp'

autoload :Base64, 'base64'

class OnBoard
  module Service
    module RADIUS
      class Passwd

        autoload :Recovery, 'onboard/service/radius/passwd/recovery'

        ENCRYPT = {
          'Cleartext-Password'  => 
              lambda{|cleartxt| cleartxt},

          'Crypt-Password'      => 
              lambda{|cleartxt| cleartxt.salted_crypt}, 

          'MD5-Password'        => 
              lambda{|cleartxt| Digest::MD5.hexdigest cleartxt},

          'SMD5-Password'       => 
              lambda{|cleartxt| Digest::MD5.salted_hexdigest cleartxt},

          'SHA1-Password'       => 
              lambda{|cleartxt| Digest::SHA1.base64digest cleartxt},

          'SSHA1-Password'      => 
              lambda{|cleartxt| Digest::SHA1.salted_base64digest cleartxt},
        }

        TYPES = ENCRYPT.keys

        CHECK = {
          'Cleartext-Password'  => 
              lambda{|cleartxt, stored| cleartxt == stored},

          'Crypt-Password'      => 
              lambda do |cleartxt, stored| 
                # salt is at the beginning, as opposed to MD5 and SHA1
                salt = stored[0..1]
                cleartxt.crypt(salt) == stored
              end, 

          'MD5-Password'        => 
              lambda do |cleartxt, stored| 
                Digest::MD5.hexdigest(cleartxt) == stored
              end,

          'SMD5-Password'       => 
              lambda do |cleartxt, stored| 
                salt = stored.hex2bin[Digest::MD5.digest_length..-1] 
                Digest::MD5.salted_hexdigest(cleartxt, salt) == stored
              end,

          'SHA1-Password'       => 
              lambda do |cleartxt, stored| 
                Digest::SHA1.base64digest(cleartxt) == stored
              end,

          'SSHA1-Password'      => 
              lambda do |cleartxt, stored|
                salt = Base64.decode64(stored)[Digest::SHA1.digest_length..-1]
                Digest::SHA1.salted_base64digest(cleartxt, salt) == stored
              end,
        }

        RANDOMLY_GENERATED_LENGTH = 6 # opinionated

        class UnknownType < ArgumentError; end

        class << self
          
          #   Password.recovery(:email => 'user@domain.com')
          def recovery(h)
            user = User.find :Email => h[:email]
            password = generate_random
            # Code here to actually modify the password TODO TODO
            if user
              recov = Recovery.new(
                  :config   => Recovery::Config.get,
                  :username => user.name,
                  :password => password,
              )
              LOGGER.info "Hotspot: sending new password to <#{h[:email]}> for user ``#{user.name}''"
              Service::Mail::SMTP.setup
              message = ::Mail.new do
                from    recov.from
                to      h[:email]
                subject recov.subject
                body    recov.body
              end
              message.deliver!
            else
              LOGGER.error "Hotspot password recovery: no user has email <#{h[:email]}>"
              sleep 2 # Fake some time passes to send the email...
            end
          end

          def generate_random
            length = Passwd::RANDOMLY_GENERATED_LENGTH
            # Inspired by http://stackoverflow.com/a/493230
            charset = %w{ 2 3 4 5 6 7 8 a b c d e f h j k m n p q t w x y z}
            (0...length).map{ charset.to_a[rand(charset.size)] }.join
          end

        end

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
