require 'forwardable'
require 'set'

require 'onboard/extensions/ipaddr'
require 'onboard/network/routing/route'
require 'onboard/system/command'

class OnBoard
  module Network
    module Routing
      class Table

        class NotFound < NameError; end

        def self.getAllIDs
          all = {} # will use Integers as keys
          # It's assumed that the only number->name map is here:
          File.foreach '/etc/iproute2/rt_tables' do |line|
            line.sub! /#.*$/, ''
            if line =~ /(\d+)\s+(\S+)/  
              all[$1.to_i] = $2
            end
          end
          `ip rule show`.each_line do |line|
            if line =~ /from \S+ lookup (\d+)/
              all[$1.to_i] = nil
            end
          end
          `ip route show table 0`.each_line do |line|
            if line =~ /table (\d+)/
              all[$1.to_i] = nil
            end
          end
          return all
        end

        def self.id2comment(number, name)
          if number == 0
            return 'All routes from all tables'
          elsif name == 'main'
            return 'Main table for basic routing'
          elsif name == 'local'
            return 'Special table: do not touch!'
          elsif name == 'default'
            return 'Fallback table'
          else
            return 'User defined table'
          end          
        end

        def self.get(table='main')
          ary = []

          # IPv4
          `ip -f inet route show table #{table}`.each_line do |line| 
            ary << rawline2routeobj(line, Socket::AF_INET)
          end

          raise NotFound if ary.length == 0 and $?.exitstatus != 0

          # IPv6
          `ip -f inet6 route show table #{table}`.each_line do |line| 
            ary << rawline2routeobj(line, Socket::AF_INET6)
          end

          raise NotFound if ary.length == 0 and $?.exitstatus != 0

          return self.new(ary, table)
        end

        def self.rawline2routeobj(line, af=Socket::AF_INET)
          line.strip!
          rttypes = 'unicast|local|broadcast|multicast|throw|unreachable|prohibit|blackhole|nat'
          h = {}
          if line =~ /^((#{rttypes})\s+)?(\S+)(\s+via (\S+))?(\s+dev (\S+))?(\s+table (\S+))?(\s+proto (\S+))?(\s+metric (\S+))?(\s+mtu (\S+))?(\s+advmss (\S+))?(\s+error (\S+))?(\s+hoplimit (\S+))?(\s+scope (\S+))?(\s+src (\S+))?/
            if $3 == 'default'
              dest = IPAddr.new(0, af).mask(0)
            else
              dest = IPAddr.new($3)
            end
            h = {
              :rttype     => ($2 || 'unicast'),
              :dest       => dest,
              :gw         => $5,
              :dev        => $7,
              :proto      => $11,
              :metric     => $13,
              :mtu        => $15,
              :advmss     => $17,
              :error      => $19,
              :hoplimit   => $21,
              :scope      => $23,
              :src        => $25
            }
            rawline = line.sub(/^(#{rttypes})/, '').sub(/table \S+/, '') 
            rawline += " type #{h[:rttype]}"
            h[:rawline] = rawline
          end
          #pp h
          return Route.new h
        end

        # TODO TODO TODO: DRY DRY DRY !!!
        def self.rawline2routeobj_old(line, af=Socket::AF_INET)
          case af
          when Socket::AF_INET # IPv4
            if line =~ /^((\S+)\s+)?(\S+)\s+via\s+(\S+)\s+dev\s+(\S+)\s+proto\s+(\S+)?/
              route_type = $2
              gw = IPAddr.new($4) # for some reasons global captures disappear
              dev = $5 # keep as a string
              proto = $6
              if $3 == "default"  
                dest = IPAddr.new("0.0.0.0/0")
                rawline = line.sub('default', '0.0.0.0/0').strip
              else
                dest = IPAddr.new($3)
                rawline = line.strip
              end
              return Route.new( 
                :dest       => dest,
                :gw         => gw,
                :dev        => dev,
                :rawline    => rawline,
                :route_type => route_type,
                :proto      => proto
              )
            elsif line =~ /^((\S+)\s+)?(\S+)\s+dev\s+(\S+)\s+proto\s+(\S+)?/
              route_type = $2
              deststr = $3
              dev = $4
              proto = $5
              if deststr.strip == "default"
                dest = IPAddr.new("0.0.0.0/0")
                rawline = line.sub('default', '0.0.0.0/0').strip
                deststr = "0.0.0.0/0"
              else
                dest = IPAddr.new(deststr)
                rawline = line.strip
              end
              return Route.new( 
                :dest => IPAddr.new(deststr),
                :gw   => IPAddr.new("0.0.0.0"),
                :dev  => dev,
                :rawline  => rawline,
                :route_type => route_type,
                :proto  => proto
              ) 
            end
          when Socket::AF_INET6 # IPv6
            if line =~ /^((\S+)\s+)?(\S+)\s+via\s+(\S+)(\s+dev\s+(\S+))?\s+proto\s+(\S+)?/ 
              route_type = $2
              gw = IPAddr.new($4)
              dev = $6
              proto = $7
              if $3 == "default"
                dest = IPAddr.new("::/0")
                rawline = line.sub('default', '::/0').strip
              else
                dest = IPAddr.new($3)
                rawline = line.strip
              end
              return Route.new( 
                :dest => dest,
                :gw   => gw,
                :dev  => dev,
                :rawline  => rawline,
                :route_type => route_type,
                :proto  => proto
              )
            elsif line =~ /^((\S+)\s+)?(\S+)\s+dev\s+(\S+)\s+proto\s+(\S+)?/
              route_type = $2
              proto = $5
              if $3 == "default"
                dest = IPAddr.new("::/0")
                rawline = line.sub('default', '::/0').strip
              else
                dest = IPAddr.new($3)
                rawline = line.strip
              end
              return Route.new(
                :dest => dest,
                :gw   => IPAddr.new("::"),
                :dev  => $4, # keep as a string
                :rawline  => rawline,
                :route_type => route_type,
                :proto => proto
              ) 
            end
          else 
            raise ArgumentError, "af must be either Socket::AF_INET or Socket::AF_INET6, got #{af}" 
          end
        end

        def self.route_from_HTTP_request(params) # create new or change
          str = ""
          if params['prefixlen'] =~ /^\s*$/
            if params['ip'] =~ /\//
              str << params['ip'] << ' '
            elsif params['ip'] =~ /^\s*(0\.0\.0\.0|::)\s*$/
              str << params['ip'] << '/0 '
            elsif params['ip'] =~ /^[^\w\d]*(default)?[^\w\d]*$/ 
              str << "default "
            else
              str << params['ip'] << " "
            end
          else # a prefix length in CIDR notation has been provided
            str << params['ip'] << '/' << params['prefixlen'] << ' '
          end
          str << "via #{params['gw']} "   if params['gw']   =~ /[\da-f:]/i
          str << "dev #{params['dev']} "  if params['dev']  =~ /\S/
          str << "proto static "
          table = self.get(params['table'])
          result = table.ip_route_add(str.strip, :try)
          if not result[:ok] 
            if result[:stderr] =~ /file exists/i
              LOGGER.info "Retrying \"ip route change #{str.strip}\""
              result = table.ip_route_change(str.strip) 
            else
              LOGGER.error \
                  "Couldn't add route as requested (see messages above)"
            end
          end
          return result
        end

        attr_reader :routes, :id

        def initialize(ary, table='main')
          @routes = ary
          @id = table
          @static_routes = []
        end

        def data
          @routes.map {|x| x.data} 
        end

        def ip_route_del(str)
          routeobj = self.class.rawline2routeobj(str) 
          msg = OnBoard::System::Command.run "ip route del #{str} table #{@id}", :sudo
          return msg
        end

        def ip_route_add(route, *opts) 
          str = route.to_s # so Route and String are both ok
          if opts.include? :try
            return \
                OnBoard::System::Command.run "ip route add #{str} table #@id", :sudo, :try
          else
            return \
                OnBoard::System::Command.run "ip route add #{str} table #@id", :sudo
          end
        end

        def ip_route_change(route, *opts)
          str = route.to_s # so Route and String are both ok
          opts << :sudo
          OnBoard::System::Command.run "ip route change #{str}", *opts
        end

        extend Forwardable
        def_delegator :@routes, :each, :each_route

      end
    end
  end
end
