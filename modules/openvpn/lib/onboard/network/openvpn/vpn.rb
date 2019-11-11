# So autoload works well with gems
require 'rubygems'

%w{uuid escape erubis}.each do |g|
  begin
    gem g
  rescue Gem::LoadError
    # Library could have been made available not as a gem
  end
end

autoload :TCPSocket,  'socket'
autoload :Time,       'time'
autoload :UUID,       'uuid'
autoload :Timeout,    'timeout'
autoload :Escape,     'escape'
autoload :Erubis,     'erubis'
autoload :YAML,       'yaml'

require 'onboard/extensions/ipaddr'
require 'onboard/extensions/openssl'

require 'onboard/system/process'
require 'onboard/crypto/ssl/pki'
require 'onboard/network/interface'
require 'onboard/network/routing/table'
require 'onboard/network/openvpn/convert'
require 'onboard/network/openvpn/process'
require 'onboard/network/openvpn/interface/name'

autoload :Log,        'onboard/system/log'

# TODO TODO TODO
# too many way to dentify a VPN: array_index, protable_id, uuid...
# switch everything to uuid ?

class OnBoard
  module Network
    module OpenVPN

      STATUS_UPDATE_INTERVAL = 60 # seconds # 'status' file

      UPSCRIPT ||= OpenVPN::ROOTDIR + '/etc/scripts/up'

      DEFAULT_METRIC ||= 5000
          # An HIGH value; e.g. maximum for Win XP is 9999
          # for Linux? unlimited?

      class VPN
        CONFDIR = OnBoard::CONFDIR + '/network/openvpn/vpn'

        System::Log.register_category 'openvpn', 'OpenVPN'

        def self.cleanup_config_files!(h={})
          h[:vpns] ||= getAll()
          uuids = h[:vpns].map{|vpn| vpn.data['uuid']}

          # Be safe: empty uuids list may be due to a bug? or the fact that the list is really empty?
          # We are about to remove config files here...
          return unless uuids.any?

          removed_dir = File.join CONFDIR, '.__cleanup__removed__'
          FileUtils.mkdir_p removed_dir
          Dir.glob(CONFDIR +
              '/[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]-[a-f0-9][a-f0-9][a-f0-9][a-f0-9]*').each do |fp|
            if File.directory? fp
              uuid = File.basename fp
              unless uuids.include? uuid
                FileUtils.mv fp, removed_dir
                # FileUtils.rm_r fp, :secure => true
              end
            end
          end
        end

        def self.save
          FileUtils.mkdir_p CONFDIR unless Dir.exists? CONFDIR
          @@all_vpn = getAll() unless (
              class_variable_defined? :@@all_vpn and @@all_vpn)
          File.open(
              CONFDIR + '/vpn.yml',
              'w'
          ) do |f|
            f.write(
              YAML.dump(
                @@all_vpn.map do |vpn|
                  vpn_data_internal = vpn.instance_variable_get(:@data_internal)
                  {
                    :process        => vpn_data_internal['process'],
                    :conffile       => vpn_data_internal['conffile'],
                    :start_at_boot  => vpn.data['running']
                  }
                end
              )
            )
          end
        end

        def self.restore
          datafile = DATADIR + '/etc/config/network/openvpn/vpn/vpn.yml'
          return false unless File.readable? datafile
          current_VPNs = getAll()
          YAML.load(File.read datafile).each do |h|
            if current_vpn = current_VPNs.detect{|x| h[:uuid] == x.uuid}
              next if current_vpn.data['running']
              current_vpn.start() if h[:start_at_boot]
            else
              new_vpn = new(h)
              new_vpn.start() if h[:start_at_boot]
              @@all_vpn << new_vpn
            end
          end
        end

        # This is basically useful to persist non-running VPN instances across
        # web interface restarts (not system reboots).
        def self.persist_current
          FileUtils.mkdir_p CONFDIR unless File.exists? CONFDIR
          File.open "#{CONFDIR}/vpn_current.yml", 'w' do |f|
            f.write YAML.dump @@all_vpn
          end
        end

        # get info on running OpenVPN instances
        def self.getAll

          @@all_interfaces  = Network::Interface.getAll()
          @@all_routes      = Network::Routing::Table.getCurrent()
          @@all_vpn         = [] unless (
              class_variable_defined? :@@all_vpn and @@all_vpn)

          if @@all_vpn.none? and File.readable? "#{CONFDIR}/vpn_current.yml"
            @@all_vpn = YAML.load File.read "#{CONFDIR}/vpn_current.yml" # TODO: DRY
          end

          @@all_vpn.each do |vpn|
            vpn.set_not_running # ...until we find it actually running ;)
          end

          `pidof openvpn`.split.each do |pid|
            conffile = ''
            p = OpenVPN::Process.new(pid)
            if p.cmdline.length == 2
              p.cmdline.insert 1, '--config' # "sanitize" command line
            end
            p.cmdline.each_with_index do |arg, idx|
              next if idx == 0
              if p.cmdline[idx - 1] =~ /^\s*\-\-config/
                conffile = arg
                break
               end
            end
            self.new(
              :process  => p,
              :conffile => conffile,
              :running  => true
            ).add_to_the_pool
          end
          @@all_vpn.each_with_index do |vpn,i|
            vpn.data['human_index'] = i + 1
          end
          return @@all_vpn
        end

        def self.all_cached; @@all_vpn; end

        def self.lookup(h)
          h[:all] ||= getAll
          if h[:any]
            return (
              lookup(:all => h[:all], :human_index  => h[:any]) or
              lookup(:all => h[:all], :uuid         => h[:any])
            )
          elsif h[:human_index]
            return h[:all][h[:human_index].to_i - 1]
          elsif h[:uuid]
            return h[:all].detect {|x|
              x.data['uuid']            == h[:uuid]}
          else
            return nil
          end
        end

        # opt_h:
        #   {:conffile => nil}      # use the long command line
        #   {:conffile => :auto}    #
        #   {:conffile => filename} #
        # If conffile is used, this method is only invoked on first creation of the
        # vpn instance, to generate the config file content, so changes to this method require
        # re-creation to be effective.
        def self.start_from_HTTP_request(params, opt_h={:conffile => :auto})
          params['pki'] = 'default' unless params['pki']
          ssl_pky = Crypto::SSL::PKI.new params['pki']
          easyrsa_pki = Crypto::EasyRSA::PKI.new params['pki']

          uuid = UUID.generate
          config_dir = "#{CONFDIR}/#{uuid}"
          reserve_a_tcp_port = TCPServer.open('127.0.0.1', 0)
          reserved_tcp_port = reserve_a_tcp_port.addr[1]
          cmdline = []
          cmdline << 'openvpn'
          cmdline << '--script-security' << '2'
          cmdline << '--up' << UPSCRIPT
          # cmdline << '--up-restart'
          cmdline << '--setenv' << 'HOME' << ENV['HOME']
          cmdline << '--setenv' << 'PATH' << ENV['PATH']
          cmdline << '--setenv' << 'bridge_to' << params['bridge_to']
          cmdline << '--setenv' << 'RUBYLIB' << OnBoard::ROOTDIR + '/lib'
          cmdline << '--setenv' << 'ONBOARD_DATADIR' << OnBoard::DATADIR
          cmdline << '--setenv' << 'NETWORK_INTERFACES_DATFILE' <<
              OnBoard::CONFDIR + '/network/interfaces.yml'
          cmdline << '--setenv' << 'STATIC_ROUTES_DATFILE' <<
              OnBoard::CONFDIR + '/network/routing/static_routes'
          cmdline << '--persist-tun'
          cmdline << '--management' << '127.0.0.1' << reserved_tcp_port.to_s
          cmdline << '--daemon'
          logfile = "/var/log/ovpn-#{uuid}.log"
          cmdline << '--log-append' << logfile
          cmdline << '--status' << "/var/run/ovpn-#{uuid}.status" <<
              OpenVPN::STATUS_UPDATE_INTERVAL
          cmdline << '--status-version' << '2'
          cmdline << '--ca' << case params['ca']
              when '__default__', /^__(\S*[^a-z0-9])?ca\S*__$/i
                ssl_pky.cacertpath
              else
                "'#{ssl_pky.certdir}/#{params['ca']}.crt'"
              end
          cmdline << '--cert' <<
              "'#{ssl_pky.certdir}/#{params['cert']}.crt'"
          keyfile = "#{ssl_pky.keydir}/#{params['cert']}.key"
          key = OpenSSL::PKey::RSA.new File.read keyfile
          dh = "#{ssl_pky.datadir}/dh#{key.size}.pem"
          cmdline << '--key' << "'#{keyfile}'"

          # CRL feature has been buggy even with single PKI...
          # crlfile = case params['ca']
          # when '__default__'
          #   Crypto::EasyRSA::CRL
          # else
          #   "'#{ssl_pky.certdir}/#{params['ca']}.crl'"
          # end
          # cmdline << '--crl-verify' << crlfile if File.exists? crlfile

          # TLS opts which may be useful for compat w/ older peers
          if params['tls-version-min'] =~ /\S/
            cmdline << '--tls-version-min' << params['tls-version-min']
          end
          if params['tls-cipher'] =~ /\S/
            cmdline << '--tls-cipher' << params['tls-cipher']
          end

          dev_type ||= 'tun' # default
          if params['dev-type'] =~ /^\s*(tun|tap)\s*$/
            dev_type = $1
          elsif params['dev'] =~ /^\s*(tun|tap)/
            dev_type = $1
          end
          cmdline << '--dev-type' << dev_type

          params['dev'].strip! if params['dev']
          dev_name = case params['dev']
                   when /\S/
                     params['dev']
                   else
                     OpenVPN::Interface::Name.generate(dev_type)
                   end
          cmdline << '--dev' << dev_name

          if params['server_net'] # it's a server, may be empty for TAPs
            client_config_dir = config_dir + '/clients'

            net = nil
            if params['server_net'] =~ /\S/
              net = IPAddr.new params['server_net']
            end

            if dev_type == 'tun'
              cmdline << '--server' << net.to_s << net.netmask.to_s
            elsif dev_type == 'tap'
              cmdline << '--mode' << 'server' << '--tls-server'
            end

            cmdline << '--local' << params['local_address'].to_s if
                params['local_address'] =~ /\S/
            cmdline << '--port' << params['port'].to_s
            cmdline << '--proto' << params['proto']
            cmdline << '--keepalive' << '10' << '120' # suggested in OVPN ex.
            cmdline << '--dh' << dh # Diffie Hellman params
            cmdline << '--client-config-dir' << client_config_dir
            FileUtils.mkdir_p client_config_dir
          elsif params['remote_host'] =~ /\S/
              # it's a client, one server (old API)
            cmdline <<
                '--client' << '--nobind'
            cmdline <<
                '--remote' << params['remote_host'] << params['remote_port'] << params['proto']
            cmdline << '--ns-cert-type' << 'server' if
                params['ns-cert-type_server'] == 'on'
          elsif params['remote_host'].respond_to? :each_index and
              params['remote_host'].detect{|x| x =~ /\S/}
              # client -> multiple server (for redundancy)
            cmdline << '--client' << '--nobind'
            cmdline << '--ns-cert-type' << 'server' if
                params['ns-cert-type_server'] == 'on'
            params['remote_host'].each_index do |i|
              next unless params['remote_host'][i] =~ /\S/
              params['proto'][i] = 'udp'        unless
                  params['proto'][i] =~ /\S/
              params['remote_port'][i] = '1194' unless
                  params['remote_port'][i] =~ /\S/
              cmdline << '--remote' <<
                  params['remote_host'][i] <<
                  params['remote_port'][i] <<
                  params['proto'][i]
            end
          else
            return {
              :ok => false,
              :err => "You must either specify a virtual network (for a server) or a remote host (for a client).",
              :status_http => 400 # Bad request
            }
          end
          cmdline << '--comp-lzo' if params['comp-lzo'] =~ /on|yes|true/
          reserve_a_tcp_port.close

          conffile = nil
          if opt_h[:conffile] == :auto
            conffile = "#{CONFDIR}/#{uuid}/openvpn.conf"
          elsif opt_h[:conffile] =
            conffile = opt_h[:conffile]
          end
          if conffile
            unless Dir.exists? File.dirname conffile
              FileUtils.mkdir_p File.dirname conffile
            end
            File.open conffile, 'w' do |f|
              f.puts "# autogenerated by #{self.name}"
              f.puts cmdline2conf cmdline
            end
            msg = System::Command.run <<EOF
sudo touch #{logfile}
sudo chown :#{Process.gid} #{logfile}
sudo chmod g+rw #{logfile}
cd /
UUID=#{uuid} sudo -E openvpn --config #{conffile} # -E is important!
EOF
          else
            msg = System::Command.run <<EOF
sudo touch #{logfile}
sudo chown :#{Process.gid} #{logfile}
sudo chmod g+rw #{logfile}
cd /
UUID=#{uuid} sudo -E #{cmdline.join(' ')} # -E is important!
EOF
          end

          msg[:log] = logfile
          System::Log.register({
            'path'      => logfile,
            'category'  => 'openvpn',
            'hidden'    => false
          })
          # Cleaup config dir if failed
          if msg[:err] and opt_h[:conffile] == :auto
            if Dir.exists? "#{CONFDIR}/#{uuid}"
              FileUtils.rm_r "#{CONFDIR}/#{uuid}", :secure => true
            end
          end
          return msg
        end

        def self.modify_from_HTTP_request(params)
          if params['stop'] # try to seek the right VPN by array index
            i = params['stop'].to_i - 1
                # array index = "human-friendly index" - 1
            return @@all_vpn[i].stop()
          elsif params['start']
            i = params['start'].to_i - 1
                # array index = "human-friendly index" - 1
            return @@all_vpn[i].start()
          end
        end

        # Turn the OpenVPN command line into a "virtual" configuration file
        def self.cmdline2conf(cmdline_ary) # delegate
          Convert.cmdline2conf(cmdline_ary)
        end

        attr_reader :data
        attr_writer :data

        def initialize(h)
          @data_internal = {
            'process'   => h[:process],
            'conffile'  => h[:conffile]
          }
          @data = {'running' => h[:running]}
          @data['uuid'] = uuid unless @data['uuid']
          @data['pkiname'] = h[:pkiname]
          parse_conffile() if File.file? @data_internal['conffile'] # regular
          parse_conffile(:text => cmdline2conf())
          if @data['server']
            if @data_internal['status']
              parse_status() # TODO: TCP management interface, not just file
              set_portable_client_list_from_status_data()
              # TODO?: get client info (and certificate info)
              # through --client-connect ?
            end
            parse_ip_pool() if @data_internal['ifconfig-pool-persist']
          elsif @data['client']
            @data['client'] = {} unless @data['client'].respond_to? :[]
            if @data_internal['management'] and @data['running']
              begin
                Timeout::timeout(3) do # three seconds should be fair
                  get_client_info_from_management_interface()
                end
              rescue Timeout::Error
                @data['client']['management_interface_err'] = $!.to_s
              end
            else
              @data['client']['management_interface_warn'] = 'OpenVPN Management Interface unavailable for this client connection'
            end
          end
          find_virtual_address()
          find_interface()
          find_routes()
        end

        alias to_h data

        def to_json(*a); to_h.to_json(*a); end

        # def to_yaml(*a); to_h.to_yaml(*a); end # save as object

        def modify_from_HTTP_request(params)
          if @data['server'] and @data_internal['client-config-dir']

            FileUtils.mkdir_p @data_internal['client-config-dir'] unless
                Dir.exists?   @data_internal['client-config-dir']

            @data['explicitly_configured_routes'] = []

            params['clients'].each do |client|
              next unless client['CN'] =~ /\S/
              if
                  client['delete'] == 'on' and
                  File.exists? "#{@data_internal['client-config-dir']}/#{client['CN']}"
                FileUtils.rm "#{@data_internal['client-config-dir']}/#{client['CN']}"
                next
              end

              routes      = client['routes'].lines.map{|x| x.strip}

              client_config_file =
"#{@data_internal['client-config-dir']}/#{client['CN'].gsub(' ', '_')}"
              File.open(client_config_file, 'w') do |f|
                routes.each do |route|
                  # Translate "10.11.12.0/24" -> "10.11.12.0 255.255.255.0"
                  begin
                    ip = IPAddr.new(route)
                  rescue ArgumentError
                    next
                  end
                  f.puts "iroute #{ip} #{ip.netmask}"
                  h = {'net' => ip.to_s, 'mask' => ip.netmask.to_s}
                  @data['explicitly_configured_routes'] << h unless
                      @data['explicitly_configured_routes'].include? h
                end

                f.puts Convert.textarea2push_routes client['push_routes']

              end

            end

            # now edit the vpn server config file
            text = ''
            # remove old configuration we want to change
            File.foreach(@data_internal['conffile']) do |line|
              text << line unless
                  line =~ /^\s*route\s+(\S+)\s+(\S)/ or
                  line =~ /^\s*client-to-client\s*(#.*)?$/ or
                  line =~ /^\s*push\s+"\s*route\s+(\S+)\s+(\S+).*"/
            end
            # add new one
            @data['explicitly_configured_routes'].each do |route_h|
              text << "route #{route_h['net']} #{route_h['mask']}\n"
            end
            text << "client-to-client\n" if params['client_to_client'] == 'on'
            text << Convert.textarea2push_routes(params['push_routes'])
            File.open @data_internal['conffile'], 'w' do |f|
              f.write text
            end

            # Reload openvpn configuration and restart connections
            # TODO: do not hardcode, improve System::Process
            System::Command.run(
                "kill -HUP #{@data_internal['process'].pid}", :sudo)
          end
        end

        def uuid
          unless @data['uuid']
            if @data_internal['process'].env['UUID']
              @data['uuid'] = @data_internal['process'].env['UUID']
            else
              @data['uuid'] = UUID.generate
            end
          end
          return @data['uuid']
        end

        def start
          if @data['running'] # TODO?: these are 'cached' data... "update"?
            return {:err => 'Already started.'}
          else
            pwd = @data_internal['process'].env['PWD']
            cmd = Escape.shell_command(@data_internal['process'].cmdline)
            cmd += ' --daemon' unless @data_internal['daemon']
            cmd += " --setenv HOME #{ENV['HOME']}"
            msg = System::Command.bgexec ("cd #{pwd} && UUID=#{uuid} sudo -E #{cmd}")
            msg[:ok] = true
            msg[:info] = 'Request accepted. You may check <a href="">this page</a> again to get updated info for the active VPNs. You may also check the <a href="/system/logs.html">logs</a>.'
            return msg
          end
        end

        def stop(*opts)
          msg = ''
          if @data['running'] # TODO?: these are 'cached' data... "update"?
            msg = System::Command.run(
               "kill #{@data_internal['process'].pid}", :sudo)
          end
          if opts.include? :rmlog
            logfile = @data_internal['log'] || @data_internal['log-append']
            if logfile and File.exists? logfile
              System::Command.run "rm #{logfile}", :sudo
              #pp System::Log.all # DEBUG
              #pp logfile
              System::Log.delete_if { |h| h['path'] == logfile }
              #pp System::Log.all
            end
          end
          FileUtils.rm_rf config_dir if
              config_dir and Dir.exists? config_dir and opts.include? :rmconf
          return msg
        end

        def config_dir
          uuid ? "#{CONFDIR}/#{uuid}" : nil
        end

        def set_not_running
          @data['running'] = false
        end

        def add_to_the_pool
          already_in_the_pool = false
          @@all_vpn.each_with_index do |vpn, vpn_i|
            if (
                vpn.data_internal['process'].cmdline ==
                    self.data_internal['process'].cmdline and
                vpn.data_internal['process'].env['PWD'] ==
                    self.data_internal['process'].env['PWD'] or
                vpn.uuid == self.uuid
            )
              @@all_vpn[vpn_i] = self
              already_in_the_pool = true
              break
            end
          end
          unless already_in_the_pool
            @@all_vpn << self
          end
        end


        # Turn the OpenVPN command line into a "virtual" configuration file
        def cmdline2conf
          self.class.cmdline2conf @data_internal['process'].cmdline
        end

        def find_interface
          case @data['dev']
          when 'tun', 'tap', /^\s*$/, nil, false
            interface = @@all_interfaces.detect do |iface|
              if iface.ip
                iface.ip.detect do |ip|
                  ip.addr.to_s == @data['virtual_address']
                end
              else
                nil
              end
            end
            @data['interface'] = interface.name if interface
          else
            @data['interface'] = @data['dev']
          end
        end

        def find_virtual_address
          @@all_interfaces ||= Network::Interface.getAll()
          iface = @@all_interfaces.detect do |x|
            x.name == @data['interface'] or
            x.name == @data['dev']
          end
          if @data['dev-type'] == 'tap' or @data['dev'] =~ /^tap/
            @data['virtual_addresses'] = iface.data['ip'] if iface
          elsif @data['client']
            begin
              @data['virtual_address'] = @data['client']['Virtual Address']
            rescue NoMethodError, TypeError
            end
          elsif data['server']
            @data['virtual_address'] = IPAddr.new(
                "#{@data['server']}/#{data['netmask']}"
            ).to_range.to_a[1].to_s
          end
        end

        def find_routes
          ary = []
          @@all_routes.routes.each do |route|
            if  @data['interface'] and
                @data['interface'] =~ /\S/ and
                @data['interface'] == route.data['dev']
              ary << route.data
            end
          end
          data['routes'] = ary
        end

        def find_client_certificates_from_pki(pkiname, opts={})
          ssl_pki = Crypto::SSL::PKI.new(pkiname)
          ssl_pki.getAllCerts(opts).select do |key, value| #Facets
            cert = value['cert']
            cert['issuer'] == data['ca']['subject'] and not
            cert['subject'] == data['cert']['subject']
                # exclude the server cert itself
          end
        end

        def parse_conffile(opts={})
          @data['explicitly_configured_routes'] = [] unless
            @data['explicitly_configured_routes'].respond_to? :[]

          text = nil
          if opts[:text]
            text = opts[:text]
          else
            if opts[:file]
              conffile = find_file opts[:file]
            else
              conffile = find_file @data_internal['conffile']
            end
            begin
              text = File.read conffile
            rescue
              @data['err'] = "couldn't open config file: '#{conffile}'"
              if @data_internal['conffile'] =~ /\S/
                @data['err'] << " '#{@data_internal['conffile']}'"
              end
              return false
            end
          end

          text.each_line do |line|
=begin
# this is a comment
#this too
a_statement # this is a comment # another comment
address#port # 'port' was not a comment (for example, dnsmasq config files)
=end
            next if line =~ /^\s*[;#]/
            line.sub! /\s+[;#].*$/, ''

            # "public" options with no arguments ("boolean" options)
            %w{duplicate-cn client-to-client client comp-lzo}.each do |optname|
              if line =~ /^\s*#{optname}\s*$/
                @data[optname] = true
                next
              end
            end

            # "public" options with 1 argument
            %w{port proto dev dev-type max-clients local comp-lzo}.each do |optname|
              if line =~ /^\s*#{optname}\s+(.*)\s*$/
                @data[optname] = $1
                next
              end
            end

            if line =~ /^\s*mode\s+server\s*$/ or line =~ /^\s*tls-server\s*$/
              @data['server'] ||= true
            end

            # "public" options with more arguments
            if line =~ /^\s*server\s+(\S+)\s+(\S+)/
              @data['server']             = $1
              @data['netmask']            = $2
              next
            elsif line =~ /^\s*remote\s+(\S+)\s+(\S+)\s*$/
              @data['remote']             ||= []
              @data['remote'] << {
                'address' => $1,
                'port'    => $2
              }
              next
            elsif line =~ /^\s*remote\s+(\S+)\s+(\S+)\s+(\S+)\s*$/
              @data['remote']             ||= []
              @data['remote'] << {
                'address' => $1,
                'port'    => $2,
                'proto'   => $3
              }
            end

            # "public" options with more arguments, multiple times
            if line =~ /^\s*route\s+(\S+)\s+(\S+)/
              h = {'net' => $1, 'mask' => $2} # TODO? 'gateway', 'metric' (RTFM)
              @data['explicitly_configured_routes'] << h unless
                  @data['explicitly_configured_routes'].include? h
            end
            # TODO: DRY with parse_client_config code: How?
            if line =~ /^\s*push\s+"\s*route\s+(\S+)\s+(\S+).*"/
              @data['push'] ||= {}
              @data['push']['routes'] ||= []
              @data['push']['routes'] << {'net' => $1, 'mask' => $2}
            end

            # "private" options with no args
            %w{daemon}.each do |optname|
              if line =~ /^\s*#{optname}\s*$/
                @data_internal[optname] = true
                next
              end
            end

            # "private" options with 1 argument
            %w{key dh ifconfig-pool-persist status status-version log log-append client-config-dir}.each do |optname|
              if line =~ /^\s*#{optname}\s+(\S+)\s*$/
                @data_internal[optname] = $1
                if optname == 'log' or optname == 'log-append'
                  logfile = find_file $1
                  System::Log.register({
                      'path' => logfile,
                      'category' => 'openvpn',
                      'hidden' => false
                  })
                end
                next
              end
            end

            %w{ca cert}.each do |optname|
              if line =~ /^\s*#{optname}\s+(\S.*\S)\s*$/
                # match filenames containing spaces
                filepath = $1
                @data['pkiname'] = Crypto::SSL::PKI.guess_pkiname :filepath => filepath
                if file = find_file(filepath)
                  begin
                    c = OpenSSL::X509::Certificate.new(File.read file)
                    @data_internal[optname] = c

                    # NOTE: this is a 'lossy' conversion (name_val_type[2] is lost)
                    # I guess we won't need the "type" "field".
                    #
                    # c.issuer.to_a and c.subject.to_a are Arrays made up of
                    # Arrays of three elements each
                    issuer__to_h = {}
                    c.issuer.to_a.each do |name_val_type|
                      issuer__to_h[name_val_type[0]] = name_val_type[1]
                    end
                    subject__to_h = {}
                    c.subject.to_a.each do |name_val_type|
                      subject__to_h[name_val_type[0]] = name_val_type[1]
                    end
                    @data[optname] = {
                      'serial'      => c.serial.to_i,
                      'issuer'      => issuer__to_h,
                      'subject'     => subject__to_h,
                      'not_before'  => c.not_before,
                      'not_after'   => c.not_after
                    }
                  rescue OpenSSL::X509::CertificateError
                    @data_internal[optname] = $!
                    @data[optname] = {'err' => $!.to_s}
                  end
                  next
                else
                  @data_internal[optname] = Errno::ENOENT
                  @data[optname] = {'err' => "File not found or not readable: #{$1}"}
                end
              end
            end

            # "private" options with 2 args
            if line =~ /^\s*status\s+(\S+)\s+(\S+)\s*$/
              @data_internal['status'] = $1
              @data_internal['status_update_seconds'] = $2
              @data['status_update_seconds'] =
                  @data_internal['status_update_seconds']
                      # keep also in @data_internal for compatibility
              next
            elsif line =~ /^\s*keepalive\s+(\S+)\s+(\S+)\s*$/
              @data_internal['keepalive'] = {
                'interval'  => $1,
                'timeout'   => $2
              }
              @data_internal['ping'] = @data_internal['keepalive'] # an alias..
            elsif line =~ /^\s*management\s+(\S+)\s+(\S+)\s*$/
              address = $1
              port = $2
              address = '127.0.0.1' if
                  address =~ /(\*|0\.0\.0\.0|::)/ and not
                  address =~ /[a-f\d]::/i and not
                  address =~ /::[a-f\d]/i
                # if "listen on any" (not recommended, though) is set,
                # this doesn't mean we will telnet to 0.0.0.0 or :: ;-)
              @data_internal['management'] = {
                'address' => address,
                'port'    => port
              }
              # TODO: configuration of the management interface may be more
              # complicated than that! See OpenVPN docs.
            elsif line =~ /^\s*ifconfig\s+(\S+)\s+(\S+)\s*$/
              @data_internal['ifconfig'] = {
                'address'                 => $1,
                'remote_peer_or_netmask'  => $2
              }
            end

            # TODO or not TODO
            # TODO? server-bridge
            # TODO? push "redirect-gateway def1 bypass-dhcp"

          end
          if @data_internal['status'] and not @data_internal['status-version']
            @data_internal['status-version'] = '1'
          end
          parse_client_config
        end

        def parse_client_config
          return false unless @data_internal['client-config-dir']
          @data['client-config'] = {}
          if Dir.exists? @data_internal['client-config-dir']
            Dir.foreach @data_internal['client-config-dir'] do |cn|
              next if cn =~ /^\./ # skip directories and hidden files
              @data['client-config'][cn] = {
                'routes'      => [],
                'iroutes'     => [],
                'push'        => {
                  'routes'      => []
                }
              }
              File.foreach "#{@data_internal['client-config-dir']}/#{cn}" do |l|
                l.sub! /#.*$/, '' # remove comments
                case l
                when /^\s*iroute\s+(\S+)\s+(\S+)/
                  @data['client-config'][cn]['iroutes'] <<
                      {'net' => $1, 'mask' => $2}
                  next
                when /^\s*route\s+(\S+)\s+(\S+)/
                  @data['client-config'][cn]['routes'] <<
                      {'net' => $1, 'mask' => $2}
                  next
                when /^\s*push\s+"\s*route\s+(\S+)\s+(\S+).*"/
                  @data['client-config'][cn]['push']['routes'] <<
                      {'net' => $1, 'mask' => $2}
                end
              end
            end
          end
        end

        def parse_status
          @data_internal['status_data'] = {}
          @data_internal['status_data']['client_list'] = {}
          @data_internal['status_data']['client_list']['clients'] = []
          @data_internal['status_data']['routing_table'] = {}
          @data_internal['status_data']['routing_table']['routes'] = []

          status_file = find_file @data_internal['status']

          unless status_file
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
          routing_table_fields      = []

          # File.foreach(status_file) do |line| # permission problems...
          `sudo cat #{status_file}`.each_line do |line|
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
          # File.foreach(status_file) do |line| # permission problems? use sudo!
          `sudo cat #{status_file}`.each_line do |line|
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

          case @data_internal['status-version'].to_s
          when /1/
            ary = @data_internal['status_data']['client_list']['clients'].dup
            ary.each do |client|
              # the term 'route' is somewhat confusing; it's used in
              # the status file...
              route = @data_internal['status_data']['routing_table']['routes'].detect { |x| x['Real Address'] == client['Real Address'] }
              client['Virtual Address'] = route['Virtual Address'].dup
              client['Connected Since'] = Time.parse client['Connected Since']
            end
          when /2/
            ary = @data_internal['status_data']['client_list']['clients'].dup
            ary.each do |client|
              t = client['Connected Since (time_t)'].to_i
              if t > 0
                client['Connected Since'] =
                    Time.at t
              else
                client['Connected Since'] =
                    Time.parse client['Connected Since']
              end
              # creating a Time object from a Unix timestamp should be
              # more efficient than parsing a human readable string, so
              # use the former when available
            end
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

          ip_pool_file = find_file @data_internal['ifconfig-pool-persist']

          unless ip_pool_file
            @data['ip_pool']['err'] = "no readable IP pool file has been found -- @data_internal['ifconfig-pool-persist'] = #{@data_internal['ifconfig-pool-persist']}"
            return false
          end

          File.foreach(ip_pool_file) do |line|
            line.strip!
            h = {}
            h['Common Name'], h['Virtual Address'] = line.split(',')
            @data['ip_pool']['pool'] << h
          end
        end

        def get_client_info_from_management_interface
          begin
            tcp = TCPSocket.new(
                @data_internal['management']['address'],
                @data_internal['management']['port']
            )
          rescue
            @data['client'] = {} unless @data['client'].respond_to? :[]
            @data_internal['management']['err'] = $!
            @data['client']['management_interface_err'] = $!.to_s
            return false
          end

          tcp.gets =~ /OpenVPN Management Interface/ or return false
          # gets the 'banner', or fails...

          tcp.puts 'state'
          @data_internal['management']['state'] = tcp.gets.strip.split(',')
          @data_internal['management']['status'] = {}
          until tcp.gets.strip == 'END'; end

          tcp.puts 'status'
          loop do
            line = tcp.gets.strip
            break if line == 'END'
            keyval = line.split(',')
            if keyval.length == 2
              key, val = keyval
              @data_internal['management']['status'][key] = val
            end
          end
          tcp.puts 'exit'
          tcp.close

          @data['client'] = {
            # 'Common Name'           =>
            #     TODO: an OpenSSL/TLS/x509 class ? ,
            'Virtual Address'         =>
                @data_internal['management']['state'][3],
            'Bytes Received'          =>
                @data_internal['management']['status']['TCP/UDP read bytes'],
            'Bytes Sent'              =>
                @data_internal['management']['status']['TCP/UDP write bytes'],
            'Connected Since'          => Time.at(
                @data_internal['management']['state'][0].to_i)
          }
        end

        def logfile
          find_file(@data_internal['log'] || @data_internal['log-append'])
        end

        def clientside_configuration(h)
          vpn     = self
          remote  = h[:remote]
          ca      = h[:ca]
          cert    = h[:cert]
          key     = h[:key]
          port    = h[:port]
          tmpl = Erubis::Eruby.new File.read(
              File.join ROOTDIR, 'templates/client.conf.erb')
          tmpl.result(binding)
        end

        protected

        def data_internal
          @data_internal
        end

        private

        # Find out the right path to config files, status logs etc.
        def find_file(name)

          return false unless name

          attempts = []
          attempts << name
          attempts << File.join(
              @data_internal['process'].env['PWD'],
              name
          ) if @data_internal['process'].env['PWD'] and name

          unless @data_internal['conffile'].strip == name.strip
            attempts << File.join(
              File.dirname(@data_internal['conffile']),
              name
            )
          end

          attempts.each do |attempt|
            return attempt if File.exists? attempt
              # it may be root:root -rw-------, but still good: will be
              # read with "sudo cat"
          end

          # try to remove quotes....
          if name =~ /^\s*'(.*)'\s*$/ or name =~ /^\s*"(.*)"\s*$/
            return find_file $1
          end

          return false
        end

      end
    end
  end
end
