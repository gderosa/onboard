require 'onboard/configurable'

class OnBoard
  module Service
    module RADIUS
      class Passwd
        class Recovery
          class Config
            CONFDIR   = RADIUS::CONFDIR + '/passwd'
            CONFFILE  = CONFDIR + '/recovery.yml'
            include Configurable
          end
        end
      end
    end
  end
end
