require 'onboard/extensions/ipaddr'

class OnBoard
  module Network
    class Routing
      class Route
        attr_reader :dest, :gw, :dev, :rawline
        def initialize(h)
          @dest       = h[:dest]    # IPAddr object
          @gw         = h[:gw]      # IPAddr object
          @dev        = h[:dev]     # String
          @rawline    = h[:rawline] # String
        end
        def data
          {
            "dest"    => @dest.data,
            "gw"      => @gw.data,
            "dev"     => @dev,
            "rawline" => @rawline
          }
        end
      end
    end
  end
end
