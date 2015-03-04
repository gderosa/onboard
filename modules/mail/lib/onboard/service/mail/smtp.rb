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
              smtp_h = {
                :address              => conf.host,
                :port                 => conf.port,
                :user_name            => (conf.username if conf.username =~ /\S/),
                :password             => (conf.password if conf.password =~ /\S/),
                :authentication       => (:plain        if conf.username =~ /\S/),
                :enable_starttls_auto => (conf.starttls =~ /on|yes|true/i),
                :openssl_verify_mode  => OpenSSL::SSL::VERIFY_NONE
                  # Unsecure, but hostnames often don't match...
              }
              # p smtp_h # DEBUG
              delivery_method :smtp, smtp_h
            end
          end

        end
      end
    end
  end
end
