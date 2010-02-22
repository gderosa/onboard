autoload :IPAddr, 'onboard/extensions/ipaddr'

class OnBoard

  module System
    autoload :Process, 'onboard/system/process'
  end

  module Network
    
    autoload :Interface, 'onboard/network/interface'

    module AccessControl
      class Chilli
        DEFAULT_SYS_CONF_FILE = '/etc/chilli.conf'
        DEFAULT_NEW_CONF_FILE = "#{CONFDIR}/defaults/chilli.conf"

        class BadRequest < RuntimeError; end

        def self.getAll
          ary = []
          # running processes
          `pidof chilli`.split.each do |pid|
            ary << new( # new Chilli object
              :process => OnBoard::System::Process.new(pid)
            )
          end
          # may be not running, but a configuration files exists
          Dir.glob("#{CONFDIR}/current/chilli.conf.?*").each do |conffile|
            chilli = new(:conffile => conffile) 
            ary << chilli unless 
                ary.detect{|x| x.conffile == conffile} or
                !chilli.validate_conffile
          end
          return ary
        end

        def self.parse_conffile(filename)
          h = {}
          File.foreach(filename) do |line|
            line.sub! /#.*$/, ''
            if line =~ /(\S+)\s+(.*)\s*$/  
              opt, arg = $1, $2
              arg.strip!
              if arg =~ /^"(.*)"$/ # remove double quote
                arg = $1
              end
              if arg == "" # NOTE: necessary ?
                arg = true
              end
            elsif line =~ /^\s*(\S+)\s*$/
              opt, arg = $1, true
            else
              next
            end
            h[opt] = arg
          end
          return h
        end

        def self.create_from_HTTP_request(params) 
          validate_HTTP_creation(params)
          chilli_new = new(:conffile => DEFAULT_NEW_CONF_FILE)
          chilli_new.conf.merge! params['conf'] 
          return chilli_new
        end

        def self.validate_HTTP_creation(params)
          unless params['conf']['dhcpif'] and params['conf']['dhcpif'] =~ /\S/
            raise BadRequest, "No network interface provided!"
          end
        end

        attr_reader :data, :conf, :managed 
            # no :conffile getter : there's already an explicit method
        attr_writer :conf, :conffile
        
        def initialize(h)
          if h[:process] 
              # Running Chilli instance
            @process = h[:process]
            @conffile = conffile()
            @conf = self.class.parse_conffile(@conffile)
            @managed = managed?
          elsif h[:conffile] and not h[:conf] 
              # Not running, but a configuration file exists
            @process = nil
            @conffile = h[:conffile]
            @conf = self.class.parse_conffile(@conffile) 
            @managed = managed?
          elsif h[:conffile] and h[:conf] 
              # We will have to write a configuration file
            @conffile = h[:conffile]
            @managed = true
            @conf = h[:conf] 
          end
        end

        def validate_conffile # based on chilli_opt(1) 
          msg = System::Command.run "chilli_opt --conf #{@conffile}", :sudo
          if msg[:ok]
            return true
          else
            LOGGER.error "Found an invalid Chilli configuration file: #{@conffile}"
            return false
          end
        end

        def running?
          return true if @process
          return false
        end

        def write_conffile
          File.open @conffile, 'w' do |f|
            @conf.each_pair do |key, value|
              if value == true
                f.write "#{key}\n"
              elsif value.respond_to? :strip! # String-like
                value.strip!
                if value =~ /\s/
                  value = "\"#{value}\"" 
                end
                f.write "#{key}\t#{value}\n"
              end
            end
          end
        end

        # true if the config file is a subdirectory of 
        # OnBoard::Network::AccessControl::Chilli::CONFDIR
        def managed?
          return true if @conffile[CONFDIR] 
          return false
        end

        def conffile
          # cache...
          if instance_variable_defined? :@conffile and @conffile
            return @conffile
          end
          cmdline = @process.cmdline # Array, like in ARGV ...
          index = cmdline.index('--conf') 
          unless index # --conf option not found
            @conffile = DEFAULT_SYS_CONF_FILE
            return @conffile 
          end
          argument = cmdline[index + 1] 
          if argument =~ /^\-/
            fail "bad chilli command line: #{cmdline.inspect}" 
          end
          if argument =~ /^\// # absolute path
            @conffile = argument
          else
            @conffile = File.join @process.cwd, argument
          end
          return @conffile
        end

        def dhcp_range
          begin
            ip_net = IPAddr.new @conf['net']
          rescue
            return nil
          end
          ip_uamlisten = IPAddr.new @conf['uamlisten']
          if conf['dhcpstart']
            ip_dhcpstart = ip_net + @conf['dhcpstart']
          else
            ip_dhcpstart = ip_net + 1
            if ip_dhcpstart == ip_uamlisten
              ip_dhcpstart += 1
            end
          end
          if conf['dhcpend']
            ip_dhcpend = ip_net + @conf['dhcpend'] 
          else
            ip_dhcpend = ip_net.to_range.last - 1
          end
          return (ip_dhcpstart..ip_dhcpend) 
        end

        def data
          {
            'process'   => {
              'pid'       => @process.pid,
              'cmdline'   => @process.cmdline,
              'cwd'       => @process.cwd
            },
            'conffile'  => conffile(),
            'conf'      => @conf.remove{|key,val| key =~ /secret/}, 
                # do not export passwords
            'dhcprange' => {
              'start'     => dhcp_range.first.to_s,
              'end'       => dhcp_range.last.to_s
            }
          }
        end

      end
    end
  end
end

