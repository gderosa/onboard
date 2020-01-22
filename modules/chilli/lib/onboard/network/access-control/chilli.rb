require 'fileutils'

require 'onboard/extensions/ipaddr'
require 'onboard/system/process'
require 'onboard/network/interface'
require 'onboard/network/interface/ip'

class OnBoard
  module Network
    module AccessControl
      class Chilli

        DEFAULT_SYS_CONF_FILE = '/etc/chilli.conf'
        DEFAULT_NEW_CONF_FILE = "#{ROOTDIR}/etc/defaults/chilli.conf"
        CURRENT_CONF_GLOB     = "#{CONFDIR}/current/chilli.conf.?*"
        SAVED_DAT_FILE        = "#{CONFDIR}/saved/chilli.dat"
        DEFAULT_COAPORT       = 3779

        class BadRequest < RuntimeError; end

        def self.save
          FileUtils.mkdir_p File.dirname SAVED_DAT_FILE
          all = getAll
          File.open SAVED_DAT_FILE, 'w' do |f|
            f.write Marshal.dump(getAll)
          end
        end

        def self.restore
          if File.exists? SAVED_DAT_FILE
            all_saved = Marshal.load File.read SAVED_DAT_FILE
            all_saved.map{|chilli| chilli.start if chilli.running?}
          end
        end

        def self.all_pids_from_pidfiles
          pids = []
          Dir.glob(CURRENT_CONF_GLOB).each do |conffile|
            chilli = new(:conffile => conffile)
            if chilli.conf['pidfile']
              if File.exists? chilli.conf['pidfile']
                pid = File.read(chilli.conf['pidfile']).to_i
                if pid > 0
                  pids << pid
                end
              end
            end
          end
          pids
        end

        def self.getAll
          ary = []
          # running processes
          `pidof chilli`.split.each do |pid_str|
            pid = pid_str.to_i
            ary << new( # new Chilli object
              :process => OnBoard::System::Process.new(pid)
            ) # if all_pids_from_pidfiles.include? pid
              #
              # The above has been commented out in order to handle pidfile
              # mismatches that may happen in real world (after abrupt system
              # exits etc.). We want to be able to detect processes who have
              # not a correct pidfile, terminate them, start new ones etc.
          end
          # may be not running, but a configuration files exists
          Dir.glob(CURRENT_CONF_GLOB).each do |conffile|
            chilli = new(:conffile => conffile)
            ary << chilli unless
                ary.detect{|x| x.conffile == conffile} or
                !chilli.validate_conffile
          end
          return ary
        end

        def self.parse_conffile(filename)
          h = {}
          return h unless File.exists? filename
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
          if params['conf']['macauth']
            params['conf']['macauth'] = true  # instead of "on" string
          else
            params['conf'].delete 'macauth'  # instead of some falsey value, just remove the key
          end
          chilli_new.conf.merge! params['conf']
          chilli_new.set_dhcp_range(params['dhcp_start'], params['dhcp_end'])
          chilli_new.dynaconf # set temporary dirs, ipc, etc.
          return chilli_new
        end

        def self.validate_HTTP_creation(params)
          dhcpif        = params['conf']['dhcpif']
          net           = params['conf']['net']
          uamlisten     = params['conf']['uamlisten']
          dhcp_start    = params['dhcp_start']
          dhcp_end      = params['dhcp_end']

          ip_net        = nil
          ip_uamlisten  = nil
          ip_dhcp_start = nil
          ip_dhcp_end   = nil

          if dhcpif =~ /\S/
            unless Interface.getAll.detect{|netif| netif.name == dhcpif}
              raise BadRequest, "Network interface #{dhcpif} does not exist"
            end
          else
            raise BadRequest, "No network interface provided!"
          end
          if net =~ /\S/
            begin
              ip_net = IPAddr.new net
              unless net =~ /\//
                raise BadRequest, "\"#{net}\" is not a valid network: maybe you forgot to specify a netmask/prefixlen?"
              end
            rescue ArgumentError
              raise BadRequest, "\"#{net}\" is not a valid network!"
            end
          else
            raise BadRequest, "No network specified!"
          end
          if uamlisten =~ /\S/
            unless Interface::IP.valid_address? uamlisten
              raise BadRequest, "\"#{uamlisten}\" is not a valid listen address!"
            else
              unless ip_net.include? IPAddr.new uamlisten
                raise BadRequest, "Listen address #{uamlisten} is outside network #{net} !"
              end
            end
          end # if blank, will defaults to the first address of the network...
          if params['conf']['uamsecret'].length > 0 and
              params['conf']['uamsecret'] != params['verify_conf']['uamsecret']
            raise BadRequest, "UAM passwords do not match!"
          end
          if
              params['conf']['macauth'] and
              params['conf']['macpasswd'].length > 0 and
              params['conf']['macpasswd'] != params['verify_conf']['macpasswd']
          raise BadRequest, "MAC-auth passwords do not match!"
        end
          return true
        end

        def self.validate_conffile(h) # based on chilli_opt(1)
          msg = System::Command.run "chilli_opt --conf #{h[:file]}", :sudo
          if msg[:ok]
            return true
          else
            LOGGER.error "Found an invalid Chilli configuration file: #{@conffile}: #{msg[:stderr]}"
            if h[:raise_exception]
              raise BadRequest, "Invalid configuration! #{msg[:stderr]}"
            end
            return false
          end
        end

        attr_reader :data, :conf, :managed
            # no :conffile getter : there's already an explicit method
        attr_writer :conf, :conffile

        def initialize(h)
          # TODO? It would probably be more efficient to store IP address
          # objects as instance variables instead of just storing Strings
          # (and create IPAddr or Interface::IP objects each time
          # we need to perform some computation...)
          # NOTE: apparently, performance is pretty good, anyway.
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
            dynaconf_coaport unless @conf['coaport'].to_i > 0
          elsif h[:conffile] and h[:conf]
              # We will have to (over-)write a configuration file
            @conffile = h[:conffile]
            @managed = true
            @conf = h[:conf]
            dynaconf_coaport unless @conf['coaport'].to_i > 0 # useless?
          end
        end

        def validate_conffile(h={})
          self.class.validate_conffile(h.merge(:file => @conffile))
        end

        def write_tmp_conffile_and_validate(opt_h={})
          write_conffile(
            :tmp => true,
            :check => true,
            :raise_exception => opt_h[:raise_exception]
          )
        end

        def set_dhcp_range(dhcp_start, dhcp_end)
          ip_net = IPAddr.new @conf['net']

          # validation and conversion code
          if dhcp_start =~ /\S/ and dhcp_end =~ /\S/
            if  Interface::IP.valid_address? dhcp_start and
                Interface::IP.valid_address? dhcp_end
              ip_dhcp_start = IPAddr.new dhcp_start
              ip_dhcp_end   = IPAddr.new dhcp_end
              if ip_net.include? ip_dhcp_start and ip_net.include? ip_dhcp_end
                if ip_dhcp_start > ip_dhcp_end
                  raise BadRequest, "\"#{dhcp_start}\"..\"#{dhcp_end}\" is not a valid DHCP interval!"
                end
              else
                raise BadRequest, "Interval \"#{dhcp_start}\"..\"#{dhcp_end}\" is outside network #{net} !"
              end
            else
              raise BadRequest, "\"#{dhcp_start}\"..\"#{dhcp_end}\" is not a valid DHCP interval!"
            end
          end

          # actual set of @conf['dhcpstart'] and @conf['dhcpend']
          if (ip_dhcp_start and ip_dhcp_end and ip_net)
            @conf['dhcpstart']  = (ip_dhcp_start - ip_net).to_i.to_s
            @conf['dhcpend']    = (ip_dhcp_end   - ip_net).to_i.to_s
          end
        end

        def dynaconf
          System::Command.run(
              "mkdir -p /var/run/chilli/#{@conf['dhcpif']}", :sudo
          )
          @conf['cmdsocket']  = "/var/run/chilli/#{@conf['dhcpif']}/chilli.sock"
          @conf['pidfile']    = "/var/run/chilli/#{@conf['dhcpif']}/chilli.pid"
          @conf['statedir']   = "/var/run/chilli/#{@conf['dhcpif']}"
          @conf['tundev']     = "chilli_#{@conf['dhcpif']}"
        end

        def dynaconf_coaport
          all_except_self = self.class.getAll.reject do |x|
            x.conf['dhcpif'] == self.conf['dhcpif']
          end
          forbidden_coaports = all_except_self.map{|x| x.conf['coaport']}
          coaport = DEFAULT_COAPORT
          while forbidden_coaports.include? coaport.to_s
            coaport += 1
          end
          @conf['coaport'] = coaport
        end

        def running?
          return true if @process
          return false
        end

        def write_conffile(opt_h={})

          FileUtils.mkdir_p File.dirname @conffile if @conffile
          if opt_h[:tmp]
            f = Tempfile.new 'chilli-test'
          else
            f = File.open @conffile, 'w'
          end

          # Allow either static and dynamic ip in net
          if @conf['net']
            #unless @conf['statip']
              @conf['statip'] = @conf['net']
            #end
            #unless @conf['dynip']
              @conf['dynip'] = @conf['net']
            #end
          end
          # until a form field is created, dynip & statip
          # should be *always* updated

          @conf.each_pair do |key, value|
            if value == true
              f.write "#{key}\n"
            elsif value.respond_to? :strip! and value =~ /\S/
                # String-like, non-blank
              value.strip!
              if value =~ /\s/
                value = "\"#{value}\"" # protect with double-quotes
              end
              f.write "#{key}\t#{value}\n"  # TODO: check truthy-ness?
            end
          end
          f.close
          FileUtils.cp f.path "#{f.path}.debug" if
            opt_h[:tmp] and opt_h[:debug] # keep a copy: the temp file
                # will be removed when f object is finalized
                # (if f is a Tempfile object)
          if opt_h[:validate] or opt_h[:check]
            return self.class.validate_conffile(
              :file => f.path,
              :raise_exception => opt_h[:raise_exception]
            )
          end
        end

        # true if the config file is a subdirectory of
        # OnBoard::Network::AccessControl::Chilli::CONFDIR or
        # defaults conf dir...
        def managed?
          return true if
              @conffile[CONFDIR] or @conffile[ROOTDIR + '/etc/defaults']
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

        def stop(opt_h={})
          msg = @process.kill(:wait => true, :sudo => true)
          if msg[:ok]
            @process = nil

            #restore previous IP configuration of the interface
            netif = Interface.getAll.detect{|x| x.name == @conf['dhcpif']}
            # do not perform the restore if the interface has got some
            # non-linklocal IP address
            if opt_h[:restore] and netif and
                File.exists? "#{CONFDIR}/current/#{netif.name}.dat" and (
                    !netif.ip or
                    netif.ip.reject{|i| i.addr.link_local?}.length == 0
                )
              saved_netif = Marshal.load File.read(
                  "#{CONFDIR}/current/#{netif.name}.dat"
              )
              case netif.ipassign[:method]
              when :dhcp
                netif.start_dhcp_client
              when :static
                netif.assign_static_ips saved_netif.ip
              end
            end
          end
          return msg
        end

        def start(opt_h={})
          netif = Interface.getAll.detect{|x| x.name == @conf['dhcpif']}

          # save previous IP configuration before flushing it
          if opt_h[:save] and netif and netif.ip
            if (netif.ipassign[:method] == :static and netif.ip.length > 0) or
                netif.ipassign[:method] == :dhcp
              File.open "#{CONFDIR}/current/#{netif.name}.dat", 'w' do |f|
                f.write Marshal.dump netif
              end
            end
            netif.stop_dhcp_client if netif.ipassign[:method] == :dhcp
            netif.ip_addr_flush
          end

          dynaconf # create socket dir...

          System::Command.run "chilli --conf #{@conffile}", :sudo
        end

        def restart
          msg = self.stop
          if msg[:ok]
            msg = self.start
          end
          return msg
        end

        def data
          {
            'process'   => @process ?
              {
                'pid'       => @process.pid,
                'cmdline'   => @process.cmdline,
                'cwd'       => @process.cwd
              } : nil,
            'conffile'  => conffile(),
            'conf'      => @conf.delete_if{|key,val| key =~ /secret/},
                # do not export passwords
            'dhcprange' => {
              'start'     => dhcp_range.first.to_s,
              'end'       => dhcp_range.last.to_s
            }
          }
        end

        def to_json(*a)
          data.to_json(*a)
        end

      end
    end
  end
end

