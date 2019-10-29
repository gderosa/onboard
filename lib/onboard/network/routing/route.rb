require 'fileutils'
require 'onboard/extensions/ipaddr'
require 'onboard/network/routing/constants'

class OnBoard
  module Network
    module Routing
      class Route

        STATIC_ROUTES_FILE = File.join CONFDIR, 'static_routes' if CONFDIR

        def self.save_static
          dir = File.dirname STATIC_ROUTES_FILE
          FileUtils.mkdir_p dir unless Dir.exists? dir

          File.open STATIC_ROUTES_FILE, 'w' do |f|
            f.write `ip route show table all | grep 'proto static'`
          end
        end

        #
        # opt_h[:file]
        #
        # opt_h[:match]
        # a lamda with a custom selection rule
        #
        # With no args restore all routes, reading from file at standard OnBoard
        # path.
        #
        # example (with args):
        # OnBoard::Network::Routing::Route.restore_static(
        #   :match => lambda do |line| { line =~ /dev eth0/ },  # Linux iproute2 syntax
        #   :file => '/path/to/file'
        # )
        #
        #
        def self.restore_static(opt_h={})
          if const_defined? :STATIC_ROUTES_FILE and File.exists? STATIC_ROUTES_FILE
            file = STATIC_ROUTES_FILE
          elsif opt_h[:file] and File.exists? opt_h[:file]
            file = opt_h[:file]
          else
            return false
          end
          File.foreach file do |line|
            line.strip!
            next if opt_h[:match] and not opt_h[:match].call(line)
            cmd = "ip route replace #{line}"
            System::Command.run cmd, :sudo
          end
        end

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
            object = instance_variable_get instance_variable
            if object.respond_to? :data
              h[s] = object.data
            else
              h[s] = object
            end
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
