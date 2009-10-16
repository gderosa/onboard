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
          # parse_status() if @data_internal['status']
        end

        def parse_conffile
          begin
            File.foreach(File.join(
                @data_internal['cwd'], 
                @data_internal['conffile'])) do |line|
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

              # "mixed" options with 2 args
              if line =~ /^\s*status\s+(\S+)\s+(\S+)\s*$/
                @data_internal['status'] = $1
                @data['status_update_seconds'] = $2
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

              # TODO or not TODO
              # TODO? server-bridge
              # TODO? push routes
              # TODO? client-config-dir, route
              # TODO? push "redirect-gateway def1 bypass-dhcp"

            end
            if @data_internal['status'] and not @data_internal['status-version']
              @data_internal['status-version'] = '1'
            end
          rescue
            @data_internal['err'] = "Couldn't open config file" 
            if @data_internal['conffile'] =~ /[^\s\/\\]/
              @data_internal['err'] <<
" (or couldn't get the full path of '#{@data_internal['conffile']}')"
            end
          end 
        end

      end
    end
  end
end
