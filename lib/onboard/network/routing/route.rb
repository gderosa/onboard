require 'onboard/extensions/ipaddr'

class OnBoard
  module Network
    module Routing
      class Route

        ROUTE_TYPES = %w{unicast local broadcast multicast throw unreachable prohibit blackhole nat}

        attr_reader :dest, :gw, :dev, :rawline, :route_type, :proto

        def initialize(h)
          @dest       = h[:dest]                    # IPAddr object
          @gw         = h[:gw]                      # IPAddr object
          @dev        = h[:dev]                     # String
          @rawline    = h[:rawline]                 # String
          @route_type = h[:route_type] || 'unicast' # String
          @proto      = h[:proto]                   # String
        end

        def data
          {
            "dest"        => @dest.data,
            "gw"          => @gw.data,
            "dev"         => @dev,
            "rawline"     => @rawline,
            "static"      => static?,
            "route_type"  => @route_type
          }
        end

        def to_s
          s = "#{@dest.to_cidr}"
          s << " via #{@gw.to_s}" if (@gw and @gw.to_i > 0) # exclude 0.0.0.0/*
          s << " dev #{@dev}" if @dev
          return s
        end
        alias :to_rawline :to_s

        def static?
          return (@proto == 'static')
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
