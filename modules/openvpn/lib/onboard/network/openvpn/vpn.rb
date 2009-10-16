class OnBoard
  module Network
    module OpenVPN
      class VPN

        # get info on running OpenVPN instances
        def self.getAll
          ary = []
          # NOTE: it's assumed that configuration options are only
          # in config files, not cmdline args; TODO: parse cmdline too?   
          `pidof openvpn`.split.each do |pid|
            conffile = ''
            cwd = `sudo readlink /proc/#{pid}/cwd`.strip
            cmdline = File.read("/proc/#{pid}/cmdline").split("\0")
            cmdline.each_with_index do |arg, idx|
              next if idx == 0
              if 
                  cmdline[idx - 1] =~ /^\s*\-\-config/ or not 
                  cmdline[idx - 1] =~ /^\s*\-/
                conffile = arg
              end
            end
            ary << self.new(
              :pid => pid,
              :cwd => cwd,
              :conffile => conffile
            )
          end
          return ary
        end

        attr_reader :data

        def initialize(h) 
          @data = {}
          @data_internal = {
            'cwd' => h[:cwd],
            'pid'=> h[:pid],
            'conffile' => h[:conffile]
          } 
          parse_conffile()
          if @data_internal['status']
            parse_status() 
            set_portable_client_list_from_status_data()
          end
          parse_ip_pool() if @data_internal['ifconfig-pool-persist'] 
        end

        def parse_conffile
          conffile = ''
          attempts = []
          attempts << @data_internal['conffile']
          attempts << File.join(
              @data_internal['cwd'],
              @data_internal['conffile'])
          attempts.each do |file|
            if File.readable? file
              conffile = file
            end
          end

          if conffile == ''
            @data['err'] = "couldn't open config file"
            if @data_internal['conffile'] =~ /\S/
              @data['err'] << " '#{@data_internal['conffile']}'"
            end
            return false
          end          
          
          File.foreach(conffile) do |line|
=begin
# this is a comment
#this too
a_statement # this is a comment # another comment
address#port # 'port' was not a comment (for example, dnsmasq config files) 
=end
            next if line =~ /^\s*[;#]/
            line.sub! /\s+[;#].*$/, '' 

            # "public" options with no arguments ("boolean" options)
            %w{duplicate-cn client-to-client}.each do |optname|
              if line =~ /^\s*#{optname}\s*$/
                @data[optname] = true
                next
              end
            end 

            # "public" options with 1 argument 
            %w{port proto dev max-clients}.each do |optname|
              if line =~ /^\s*#{optname}\s+(.*)\s*$/ 
                @data[optname] = $1
                next
              end
            end

            # "public" options with more arguments
            if line =~ /^\s*server\s+(\S+)\s+(\S+)/
              @data['server']   = $1
              @data['netmask']  = $2
              next
            end

            # "private" options with 1 argument
            %w{ca cert key dh ifconfig-pool-persist status status-version log log-append}.each do |optname|
              if line =~ /^\s*#{optname}\s+(\S+)\s*$/
                @data_internal[optname] = $1
                # puts line + '|' + optname + '|' + $1
                next
              end
            end

            # "private" options with 2 args
            if line =~ /^\s*status\s+(\S+)\s+(\S+)\s*$/
              @data_internal['status'] = $1
              @data_internal['status_update_seconds'] = $2
              next
            elsif line =~ /^\s*keepalive\s+(\S+)\s+(\S+)\s*$/
              @data_internal['keepalive'] = {
                'interval'  => $1,
                'timeout'   => $2
              }
              @data_internal['ping'] = @data_internal['keepalive'] # an alias..
            end

            # TODO or not TODO
            # TODO? server-bridge
            # TODO? push routes
            # TODO? client-config-dir, route
            # TODO? push "redirect-gateway def1 bypass-dhcp"

          end
          if @data_internal['status'] and not @data_internal['status-version']
            @data_internal['status-version'] = '1'
          end
        end

        def parse_status
          @data_internal['status_data'] = {}
          @data_internal['status_data']['client_list'] = {}
          @data_internal['status_data']['client_list']['clients'] = []
          @data_internal['status_data']['routing_table'] = {}
          @data_internal['status_data']['routing_table']['routes'] = []

          status_file = ''

          attempts = []
          attempts << @data_internal['status'] 
          attempts << File.join(
              File.dirname(@data_internal['conffile']), 
              @data_internal['status']
          ) 
          attempts << File.join(
              @data_internal['cwd'],
              @data_internal['status']
          )

          attempts.each do |filename|
            if File.readable? filename
              status_file = filename
              break
            end  
          end

          if status_file == ''
            @data_internal['status_data']['err'] = 'no readable status file has been found'
            return false
          end

          case @data_internal['status-version']
          when /1/
            parse_status_v1(status_file)
          when /2/
            parse_status_v2(status_file)
          else 
            raise \
                RuntimeError, 
                '@data_internal[\'status-version\'] was not set!'
          end
        end

        def parse_status_v1(status_file)
          where                     = :beginning
          got_client_list_header    = false
          got_routing_table_header  = false
          got_global_stats_header   = false
          client_list_fields        = []
          routing_table_fields     = []

          File.foreach(status_file) do |line|
            line.strip!

            where = :client_list    if line =~ /OpenVPN CLIENT LIST/
            where = :routing_table  if line =~ /ROUTING TABLE/
            where = :global_stats   if line =~ /GLOBAL STATS/ 

            if line =~ /^\s*Updated,(\S.*\S)\s*$/
              @data_internal['status_data']['updated'] = $1
            end

            if where == :client_list
              if line =~ /Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since/
                got_client_list_header = true
                client_list_fields = line.split(',') 
              elsif got_client_list_header
                h = {}
                values = line.split(',')
                break unless values.length == client_list_fields.length
                client_list_fields.each_with_index do |name, idx|
                  h[name] = values[idx]
                end
                @data_internal['status_data']['client_list']['clients'] << h
              end
            end

            if where == :routing_table
              if line =~ /Virtual Address,Common Name,Real Address,Last Ref/
                got_routing_table_header = true
                routing_table_fields = line.split(',') 
              elsif got_routing_table_header
                h = {}
                values = line.split(',')

                break unless 
                    values.respond_to? :length and
                    routing_table_fields.respond_to? :length and
                    values.length == routing_table_fields.length

                routing_table_fields.each_with_index do |name, idx|
                  h[name] = values[idx]
                end
                @data_internal['status_data']['routing_table']['routes'] << h
              end
            end

            # TODO? GLOBAL STATS?
           
          end
        end

        def parse_status_v2(status_file) # TODO: DRY
          headers = {}
          File.foreach(status_file) do |line|
            line.strip!

            if line =~ /TIME,([^,]+)/
              @data_internal['status_data']['updated'] = $1
            elsif line =~ /^HEADER,([^,]+),(.*)$/
              headers[$1] = $2.split(',') 
            elsif line =~ /^CLIENT_LIST,(.*)/
              values = $1.split(',')
              h = {}
              headers['CLIENT_LIST'].each_with_index do |hdr, idx|
                h[hdr] = values[idx]
              end
              @data_internal['status_data']['client_list']['clients'] << h
            elsif line =~ /^ROUTING_TABLE,(.*)/
              values = $1.split(',')
              h = {}
              headers['ROUTING_TABLE'].each_with_index do |hdr, idx|
                h[hdr] = values[idx]
              end
              @data_internal['status_data']['routing_table']['routes'] << h
            end

            # TODO? GLOBAL STATS?
           
          end
        end       

        def set_portable_client_list_from_status_data
          ary = []

          # NOTE: 'time_t' fields UNIX timestamps() are available on 
          # version 2 only, don't use them, altough they appear useful; work
          # with formated string instead, and convert them.
          # TODO: create the 'time_t' field, through conversion

          case @data_internal['status-version'].to_s
          when /1/
            ary = @data_internal['status_data']['client_list']['clients'].dup
            ary.each do |client|
              # the term 'route' is somewhat confusing; it's used in
              # the status file...
              route = @data_internal['status_data']['routing_table']['routes'].detect { |x| x['Real Address'] == client['Real Address'] }
              client['Virtual Address'] = route['Virtual Address'].dup
            end
          when /2/
            ary = @data_internal['status_data']['client_list']['clients']
          else
            raise RuntimeError, "status-version should be either 1 or 2, got #{@data_internal['status-version']}"
          end

          @data['clients'] = ary

        end

        def parse_ip_pool
          @data['ip_pool'] = {
            'err' => nil,
            'pool' => []
          }

          ip_pool_file = ''
          # TODO: DRY!
          attempts = []
          attempts << @data_internal['ifconfig-pool-persist'] 
          attempts << File.join(
              File.dirname(@data_internal['conffile']), 
              @data_internal['ifconfig-pool-persist']
          ) 
          attempts << File.join(
              @data_internal['cwd'],
              @data_internal['ifconfig-pool-persist']
          )

          attempts.each do |filename|
            if File.readable? filename
              ip_pool_file = filename
              break
            end  
          end

          if ip_pool_file == ''
            @data['ip_pool']['err'] = "no readable IP pool file has been found #{@data_internal['ifconfig-pool-persist']}"
            return false
          end

          File.foreach(ip_pool_file) do |line|
            line.strip!
            h = {}
            h['CN'], h['vIP'] = line.split(',') 
            @data['ip_pool']['pool'] << h
          end
        end

      end
    end
  end
end
