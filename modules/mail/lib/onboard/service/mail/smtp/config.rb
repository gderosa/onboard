require 'onboard/configurable'

require 'onboard/service/mail/constants'
require 'onboard/service/mail/smtp/constants'

class OnBoard
  module Service
    module Mail
      module SMTP
        class Config

          CONFDIR   = CONFDIR   unless const_defined? :CONFDIR
          CONFFILE  = CONFFILE  unless const_defined? :CONFFILE

          include Configurable
          
        end
      end
    end
  end
end
