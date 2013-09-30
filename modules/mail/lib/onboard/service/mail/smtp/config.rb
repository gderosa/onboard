require 'onboard/configurable'

require 'onboard/service/mail/constants'
require 'onboard/service/mail/smtp/constants'

class OnBoard
  module Service
    module Mail
      module SMTP
        class Config

          CONFFILE ||= SMTP::CONFFILE

          include Configurable
          
        end
      end
    end
  end
end
