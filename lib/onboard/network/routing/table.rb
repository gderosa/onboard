require 'forwardable'
require 'set'

require 'onboard/extensions/ipaddr'
require 'onboard/system/command'
require 'onboard/network/routing/constants'
require 'onboard/network/routing/route'
require 'onboard/network/interface'


class OnBoard
  module Network
    module Routing
      class Table
        RT_TABLES_CONFFILE = File.join Routing::CONFDIR, 'rt_tables'
        VALID_NAMES = /^[\w_-]*[a-z][\w_-]*$/i

        # Create if it doesn't exist
        unless File.exists? RT_TABLES_CONFFILE
          unless Dir.exists? File.dirname RT_TABLES_CONFFILE
            FileUtils.mkdir_p File.dirname RT_TABLES_CONFFILE
          end
          File.open RT_TABLES_CONFFILE, 'w' do |f|
          end
        end

        class NotFound < NameError; end
        class NameAlreadyInUse < NameError; end

        def self.getAllIDs
          # Hashes with numeric keys...
          system_tables = {} 
          custom_tables = {}
          comments      = {}
          # It's assumed that the only number->name map is here:
          File.foreach '/etc/iproute2/rt_tables' do |line|
            if line =~ /^(\d+)\s+([^#\s]+)(\s*#\s*(\S.*))?/  
              n = $1.to_i
              system_tables[n] = $2
              comments[n] = $4
            end
          end
          `ip rule show`.each_line do |line|
            if line =~ /from.*lookup\s+(\d+)/
              custom_tables[$1.to_i] = nil
            end
          end
          `ip route show table 0`.each_line do |line|
            if line =~ /table (\d+)/
              custom_tables[$1.to_i] = nil
            end
          end
          if File.exists? RT_TABLES_CONFFILE
            File.foreach RT_TABLES_CONFFILE do |line|
              if line =~ /^(\d+)\s+([^#\s]+)?(\s*#\s*(\S.*))?/
                n = $1.to_i
                custom_tables[n] = $2
                comments[n] = $4
              end
            end
          end
          return {
            'system_tables' => system_tables,
            'custom_tables' => custom_tables,
            'comments'      => comments
          }
        end

        def self.create_from_HTTP_request(params)
          File.open RT_TABLES_CONFFILE, 'a' do |f|
            number  = params['number']
            name    = params['name']
            comment = params['comment']
            
            f.puts "#{number} #{name} # #{comment}"
          end
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
            return nil # 'User defined table'
          end          
        end

        def self.number(table)
          # table: name or number
          if table.kind_of? Integer
            return table
          else # Must be a String, then
            table.strip!
          end
          if table =~ /^\d+$/
            return table.to_i
          end
          table_n = nil
          all_tables = getAllIDs['system_tables'].merge getAllIDs['custom_tables']
          detect = all_tables.detect{|k, v| v == table}
          if detect
            table_n = detect[0]
            return table_n.to_i
          else
            raise NotFound
          end
        end

        def self.getCurrent; self.get('main'); end # Compatibility

        def self.get(table='main')

          table_n = number(table)

          ary = []

          # IPv4
          `ip -f inet route show table #{table_n}`.each_line do |line| 
            ary << rawline2routeobj(line, Socket::AF_INET)
          end

          #raise NotFound if ary.length == 0 and $?.exitstatus != 0

          # IPv6
          `ip -f inet6 route show table #{table_n}`.each_line do |line| 
            ary << rawline2routeobj(line, Socket::AF_INET6)
          end

          #raise NotFound if ary.length == 0 and $?.exitstatus != 0

          return self.new(ary, table_n)
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
              :metric     => $13,  # buggy, parse again below
              :mtu        => $15,
              :advmss     => $17,
              :error      => $19,
              :hoplimit   => $21,
              :scope      => $23,
              :src        => $25
            }
            rawline = 
                line.sub(/^(#{rttypes})/, '').gsub(/(table|proto) \S+/, '')
            h[:rawline] = rawline
          end
          if line =~ /\smetric\s+(\d+)/
            h[:metric] = $1.to_i
          end
          return Route.new h
        end

        # TODO! should be an instance method!
        def self.change_name_and_comment(number, name='', comment='')
          old_text = File.read RT_TABLES_CONFFILE
          found = false
          File.open RT_TABLES_CONFFILE, 'w' do |f|
            old_text.each_line do |line|
              if line =~ /^\s*#{number}([^\d].*)?$/
                f.puts "#{number} #{name} # #{comment}" 
                found = true
              else
                f.write line
              end
            end
            f.puts "#{number} #{name} # #{comment}" if not found
          end
          return {:ok => true}
        end

        def self.rename(*args)
          change_name_and_comment(*args)
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

          # set metric
          metric = nil
          if params['metric'] =~ /\d/
            metric = params['metric']
          else
            ifname = nil
            if params['dev'] =~ /\S/
              ifname = params['dev']
            elsif params['gw']   =~ /[\da-f:]/i
              route_line = `ip route get #{params['gw']} | grep dev`
              if route_line =~ /dev\s+(\S+)/
                ifname = $1
              end
            end
            if ifname
              iface = Network::Interface.new :name => ifname
              iface.get_preferred_metric!
              metric = iface.preferred_metric
            end
          end
          str << "metric #{metric} " if metric
          # end set metric

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

        # @id is generally the number (Integer), but methods re-read
        # RT_TABLES_CONFFILE in case it's a (non-numerical) String
        # (e.g. the name) 

        def initialize(ary, table='main')
          @routes = ary
          @id = Routing::Table.number(table)   
        end

        def delete!
          all_rules = Rule.getAll
          if all_rules.detect{|rule| Routing::Table.number(rule.table) == self.number}
            raise OnBoard::Network::Routing::RulesExist, 
                'Couldn\'t delete: one or more rules still refer to this routing table! Delete them and try again.'
          end
          ip_route_flush
          old_text = File.read RT_TABLES_CONFFILE
          File.open RT_TABLES_CONFFILE, 'w' do |f|
            old_text.each_line do |line|
              unless line =~ /^\s*#{number}([^\d].*)?$/
                f.write line
              end
            end
          end
          return {:ok => true}
        end

        def number
          return @id if @id.kind_of? Integer
          @id.strip!
          return @id.to_i if @id =~ /^\d+$/
          h = self.class.getAllIDs
          return 
            (h['system_tables'].detect{|k, v| v == @id}[0]) or
            (h['custom_tables'].detect{|k, v| v == @id}[0])
        end

        def name
          h = self.class.getAllIDs
          if @id.kind_of? Integer
            n = @id 
            if kv = h['system_tables'].detect{|k, v| k == n}
              return kv[1]
            elsif kv = h['custom_tables'].detect{|k, v| k == n}
              return kv[1]
            end
          elsif @id.strip =~ /^[^\s\d]+$/
            return @id.strip
          end
        end

        def comment
          n = number
          self.class.getAllIDs['comments'][n] || ''
        end

        def system?
          h = self.class.getAllIDs
          return h['system_tables'].detect{|k, v| k == number}
        end

        def data
          {
            'number'  => number,
            'name'    => name,
            'system'  => system?,
            'routes'  => @routes.map {|x| x.data}
          }
        end
        alias to_h data

        def to_json(*a); to_h.to_json(*a); end
        def to_yaml(*a); to_h.to_yaml(*a); end

        def ip_route_flush
          msg = OnBoard::System::Command.run "ip route flush table #{@id}", :sudo
        end
        
        def ip_route_del(str, opt_h={})
          opt_h = {:af => 'inet'}.merge opt_h
          af = opt_h[:af]
          msg = OnBoard::System::Command.run "ip -f #{af} route del #{str} table #{@id}", :sudo
          return msg
        end

        def ip_route_add(route, *opts) 
          str = route.to_s # so Route and String are both ok
          n = number
          cmd = "ip route add #{str} table #{n}"
          if opts.include? :try
            return \
                OnBoard::System::Command.run cmd, :sudo, :try
          else
            return \
                OnBoard::System::Command.run cmd, :sudo
          end
        end

        def ip_route_change(route, *opts)
          str = route.to_s # so Route and String are both ok
          n = number
          cmd = "ip route change #{str} table #{n}"
          opts << :sudo
          OnBoard::System::Command.run "ip route change #{str} table #{n}", *opts
        end

        extend Forwardable
        def_delegator :@routes, :each, :each_route

      end
    end
  end
end
