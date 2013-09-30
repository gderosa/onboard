require 'mail'

class OnBoard
  module Service
    module Mail
      module SMTP

        autoload :Config, 'onboard/service/mail/smtp/config'

        class << self

          def setup
            conf = SMTP::Config.get
            ::Mail.defaults do
              delivery_method :smtp, { 
                :address => conf.host,
                :port => conf.port,
                :user_name => conf.username,
                :password => conf.password,
                :authentication => :plain,
                :enable_starttls_auto => (conf.starttls =~ /on|yes|true/i)
              }
            end
          end

        end
      end
    end
  end
end
