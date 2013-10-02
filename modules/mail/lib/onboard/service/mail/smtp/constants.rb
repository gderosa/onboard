require 'onboard/service/mail/constants'

class OnBoard
  module Service
    module Mail
      module SMTP
        CONFFILE = File.join Mail::CONFDIR, 'smtp.yml'
      end
    end
  end
end
