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
            "rawline" => @rawline,
            "static"  => static?
          }
        end

        def static?
          return true if Table::static_routes.detect {|sr| sr === self}
        end

        # Loose comparison. For example,
        #     1.2.3.4 via 6.7.8.9 dev eth2 
        # and
        #     1.2.3.4 via 6.7.8.9
        # are equal, but
        #     1.2.3.4 via 6.7.8.9 dev eth2
        # and    
        #     1.2.3.4 via 6.7.8.9 dev eth1
        # are not.    
        def ===(other)
          return true if rawline.strip == other.rawline.strip
          if !dev or !other.dev
            if dest == other.dest and gw == other.gw
              return true
            end
          end
          if
              dest == other.dest  and
              gw   == other.gw    and
              dev  == other.dev
            return true
          end
          return false
        end

      end
    end
  end
end
