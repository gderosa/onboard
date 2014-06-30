require 'time'

class OnBoard
  module Util
    autoload :Version, 'onboard/util/version'

    def wait_for(opts={}, &blk)
      defaults = {
        sleep: 0.2,
        timeout: 2.8
      }
      opts = defaults.merge(opts)
      t0 = Time.now
      until blk.call
        break if Time.now - t0 > opts[:timeout] and opts[:timeout] > 0
        sleep opts[:sleep]
      end
    end
  end
end
