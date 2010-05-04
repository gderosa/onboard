require 'onboard/extensions/ipaddr'

class OnBoard
  module Network
    module Routing
      class Route

        FIELDS = [:rttype, :dest, :gw, :dev, :proto, :metric, :mtu, :advmss, :error, :hoplimit, :scope, :src, :rawline]

        attr_reader *FIELDS

        def initialize(h)
          FIELDS.each do |field|
            instance_variable = ('@' + field.to_s).to_sym
            instance_variable_set instance_variable, h[field]
          end
        end

        def data
          h = {}
          FIELDS.each do |field|
            s = field.to_s
            instance_variable = ('@' + s).to_sym
            h[s] = instance_variable_get instance_variable
          end
          return h
        end

        def to_s
          s = "#{@dest.to_cidr}"
          s << " via #{@gw.to_s}" if (@gw and @gw.to_i > 0) # exclude 0.0.0.0/*
          s << " dev #{@dev}"           if @dev
          s << " type #{@rttype}"       if @rttype
          s << " proto #{@proto}"       if @proto
          s << " metric #{@metric}"     if @metric
          s << " mtu #{@mtu}"           if @mtu
          s << " advmss #{@advmss}"     if @advmss
          s << " error #@error{}"       if @error
          s << " hoplimit #{@hoplimit}" if @hoplimit
          s << " scope #{@scope}"       if @scope
          s << " src #{@src}"           if @src
          return s
        end
        alias to_rawline to_s
        alias route_type rttype

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
