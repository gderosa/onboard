require 'fileutils'

require 'onboard/util'
require 'onboard/platform/debian'
require 'onboard/system/hostname'
require 'onboard/network/interface/ip'

class OnBoard
  module Network
    class Dnsmasq

      include OnBoard::Util

      CONFDIR = OnBoard::CONFDIR + '/network/dnsmasq'
      CONFDIR_CURRENT = "#{CONFDIR}/new"
      DEFAULTS_CONFDIR = OnBoard::ROOTDIR + '/etc/defaults/network/dnsmasq'
      CONFFILES_GLOB = '*.conf'

      # Search for "--host-record" in
      # http://www.thekelleys.org.uk/dnsmasq/CHANGELOG
      REQUIRED_VERSION = {
        :host_record => Version.new('2.61')
      }
      BAD_VERSION = {
        :host_record => Version.new('2.63')
      }

      def self.save
        Dir.glob "#{CONFDIR_CURRENT}/#{CONFFILES_GLOB}" do |path|
          FileUtils.copy path, CONFDIR
        end
      end

      def self.restore
        OnBoard::System::Command.run "mkdir -p #{CONFDIR_CURRENT}"
        Dir.glob "#{DEFAULTS_CONFDIR}/#{CONFFILES_GLOB}" do |path|
          basename = File.basename path
          unless File.exists? "#{CONFDIR}/#{basename}"
            FileUtils.copy path, CONFDIR
          end
          FileUtils.copy "#{CONFDIR}/#{basename}", CONFDIR_CURRENT
        end
        OnBoard::System::Hostname.be_resolved( :no_restart )
        self.restart
      end

      def self.version
        `sudo dnsmasq -v | head -n 1` =~ /dnsmasq version ([\d\.]+)/i and
            Version.new $1
      end

      def self.init_conf
        need_restart = false
        unless File.exists? "#{CONFDIR_CURRENT}"
          FileUtils.mkdir_p "#{CONFDIR_CURRENT}"
          need_restart = true
        end
        #CONFFILES.each do |file|
        Dir.glob "#{DEFAULTS_CONFDIR}/#{CONFFILES_GLOB}" do |path|
          basename = File.basename path
          unless File.exists? File.join CONFDIR_CURRENT, basename
            FileUtils.copy "#{DEFAULTS_CONFDIR}/#{basename}", CONFDIR_CURRENT
            need_restart = true
          end
        end
        if need_restart
          OnBoard::PLATFORM::restart_dnsmasq  "#{CONFDIR_CURRENT}"
        end
      end

      def self.validate_dhcp_range(dhcp_range_params)
        return {:ignore => true} if
            dhcp_range_params['delete'] =~ /on|yes|true|1/i

        %w{ipstart ipend}.each do |what|
          return {:ignore => true} if dhcp_range_params[what] =~ /add\s*new/i
          if not OnBoard::Network::Interface::IP.valid_address?(dhcp_range_params[what])
            return {
              :ok => false,
              :err => "Invalid IP address: \"#{dhcp_range_params[what]}\""
            }
          end
        end
        return {:ok => true}
      end

      def self.validate_dhcp_host(dhcp_host_params)
        return {:ignore => true} if
            dhcp_host_params['delete'] =~ /on|yes|true|1/i
        return {:ignore => true} if
            dhcp_host_params['mac']     =~ /add\s*new/i and
            dhcp_host_params['ip']      =~ /add\s*new/i

       if not OnBoard::Network::Interface::MAC.valid_address?(dhcp_host_params['mac'])
          return {
            :ok => false,
            :err => "Invalid MAC address: \"#{dhcp_host_params['mac']}\""
          }
        end

        if not OnBoard::Network::Interface::IP.valid_address?(dhcp_host_params['ip'])
          return {
            :ok => false,
            :err => "Invalid IP address: #{dhcp_host_params['ip']}"
          }
        end

        return {:ok => true}
      end

      def self.restart
        OnBoard::PLATFORM::restart_dnsmasq("#{CONFDIR_CURRENT}")
      end

      attr_reader :data

      def initialize
        @data = {
          'conf'        => {
            'dhcp'        => {
              'ranges'      => [],
              'fixed-hosts' => []
            },
            'dns'         => {  # explicitly configured
              'nameservers' => [],
              'searchdomain'=> '',
              'localdomain' => '',
              'domains'     => {}
            }
          },
          'leases'      => [],
          'resolvconf'  => {  # tipically obtained via DHCP (appliance may be DHCP client on the external/WAN interface, and DHCP server on the internal/LAN interface)
            'file'        => '/etc/resolv.conf',
            'nameservers' => []
          }
        }
      end

      def to_h; @data; end

      def to_json(*a); to_h.to_json(*a); end
      def to_yaml(*a); to_h.to_yaml(*a); end

      def parse_dhcp_conf
        return false unless File.readable? CONFDIR + '/new/dhcp.conf'
        File.open CONFDIR + '/new/dhcp.conf' do |file|
          file.each_line do |line|
            next if line =~ /^#/
            if line =~ /^(.*)\s#/
              line = $1
              redo # remove comments like # # # # (multiple '#')
            end
            line.strip!
            # The following regexes are too 'rigid' to parse conf file
            # not written by ourselves, but should be ok for our needs.
            if line =~ /dhcp-range=([^,]+),([^,]+),([^,]+)/
              @data['conf']['dhcp']['ranges'] << {
                'ipstart'                 => $1,
                'ipend'                   => $2,
                'leasetime'               => $3
              }
            elsif line =~ /dhcp-host=([^,]+),([^,]+),([^,]+)\s*$/
              # do not assign hostnames
              @data['conf']['dhcp']['fixed-hosts'] << {
                'mac'                     => $1,
                'ip'                      => $2,
                'leasetime'               => $3
              }
            end
          end
        end
      end

      def parse_dhcp_leasefile
        dhcp_leasefile = ""
        return false unless File.readable? CONFDIR + '/new/dnsmasq.conf'
        File.open CONFDIR + '/new/dnsmasq.conf' do |file|
          file.each_line do |line|
            next if line =~ /^#/
            if line =~ /^(.*)\s#/
              line = $1
              redo # remove comments like # # # # (multiple '#')
            end
            line.strip!
            # The following regexes are too 'rigid' to parse conf file
            # not written by ourselves, but should be ok for our needs.
            if line =~ /dhcp-leasefile=(\S+)/ # TODO? handle filepath w/ spaces?
              dhcp_leasefile = $1
              break
            end
          end
        end
        if File.readable? dhcp_leasefile
          File.open dhcp_leasefile do |leasefile|
            leasefile.each_line do |line|
              if line =~ /^(\d+)\s+([\da-f]{2}:[\da-f]{2}:[\da-f]{2}:[\da-f]{2}:[\da-f]{2}:[\da-f]{2})\s+(\S+)\s+(\S+)/i # TODO? String#split would be more efficient?
                @data['leases'] << {
                  'expiry'  => $1,
                  'mac'     => $2,
                  'ip'      => $3,
                  'name'    => $4
                }
              end
            end
          end
        end
      end

      # Repeat Yourself :-P # TODO's ?
      def parse_dns_conf(filename="#{CONFDIR_CURRENT}/dns.conf")
        return false unless File.readable? filename
        File.open filename do |file|
          file.each_line do |line|
            next if line =~ /^\s*#/
            line.strip!
            # The following regexes are too 'rigid' to parse conf file
            # not written by ourselves, but should be ok for our needs.
            case line
            when /^\s*server\s*=\s*([^,\s#]+)\s*#\s?(.*)$/
              @data['conf']['dns']['nameservers'] << {
                'ip'      => $1,
                'comment' => $2
              }
            when /^\s*server\s*=\s*([^,\s#]+)/
              @data['conf']['dns']['nameservers'] << {
                'ip'      => $1,
                'comment' => ''
              }
            when /^\s*domain\s*=\s*([^,\s#]+)/
              @data['conf']['dns']['searchdomain'] << $1
            when /^\s*local\s*=\s*\/([^,\s#]+)\//
              @data['conf']['dns']['localdomain'] << $1
            when %r{^\s*address\s*=\s*/(([\w\.\-]+/)+)([a-fA-F\d\.:]+)\s*$}
              domains = $1.split('/')
              ip      = $3
              domains.each do |domain|
                @data['conf']['dns']['domains'][domain] ||= []
                @data['conf']['dns']['domains'][domain] << ip
              end
            end
          end
        end
      end

      def parse_dns_cmdline
        # NOTE: it's assumed only one dnsmasq instance at a time
        # NOTE: the only option parsed is -r
        #
        # WORKAROUND: in case of multiple instances, consider the first
        # one
        pid = `pidof dnsmasq`.split.first.to_i
        return unless pid and pid > 0
        if File.read("/proc/#{pid}/cmdline") =~ /-r\0([^\0]+)/
          @data['resolvconf']['file'] = $1
        end
        if File.exists? @data['resolvconf']['file'] 
          File.open @data['resolvconf']['file'] do |file|
            file.each_line do |line|
              if line =~ /^\s*nameserver\s+(\S+)/
                @data['resolvconf']['nameservers'] << $1
              end
            end
          end
        end
      end

      def write_dhcp_conf_from_HTTP_request(params)
        str = banner + "\n"
        params['ranges'].each_value do |range|
          msg = self.class.validate_dhcp_range(range)
          return msg if msg[:err]
          unless msg[:ignore]
            str << 'dhcp-range='
            str <<  range['ipstart']  << ',' <<
                    range['ipend']    << ',' <<
                    range['leasetime']<< "\n"
          end
        end
        params['hosts'].each_value do |host| # fixed host
          host['mac'].gsub! '-', ':' # normalize: 00-aa-bb-ff-23-45 -> 00:aa:bb:ff:23:45
          msg = self.class.validate_dhcp_host(host)
          return msg if msg[:err]
          unless msg[:ignore]
            str <<  'dhcp-host='
            str <<  host['mac']       <<  ',' <<
                    host['ip']        <<  ',' <<
                    host['leasetime'] << "\n"
          end
        end
        FileUtils.mkdir(CONFDIR + '/new') unless Dir.exists?(CONFDIR + '/new')
        FileUtils.copy(
          CONFDIR + '/new/dhcp.conf', CONFDIR + '/new/dhcp.conf~'
        ) if File.exists?(CONFDIR + '/new/dhcp.conf')
        File.open(CONFDIR + '/new/dhcp.conf',  'w') do |file|
          file.write str
        end
        return {:ok => true}
      end


      def write_dns_conf_from_HTTP_request(params={})
        str = banner + "\n"
        str_domains_self = str.clone
        if params['nameservers']
          params['nameservers'].each do |ns|
            explicit_port = false
            ns['ip'].strip!
            if ns['ip'] =~ /^(\S+)#(\d+)$/ # example: 127.0.0.1#5353
              ns['ip'] = $1
              ns['port'] = $2
              explicit_port = true
            end
            next if not \
                OnBoard::Network::Interface::IP::valid_address? ns['ip']
            if explicit_port
              str << "server=#{ns['ip']}##{ns['port']} # #{ns['comment']}\n"
            else
              str << "server=#{ns['ip']} # #{ns['comment']}\n"
            end
          end
        end

        # TODO: DRY: move some of this to write_local_domain(domain)

        params['searchdomain'] = System::Hostname.domainname \
            unless params['searchdomain'] =~ /\S/

        if params['searchdomain'].respond_to? :strip!
          params['searchdomain'].strip!
          if params['searchdomain'] =~ /^[a-z0-9\.\-]+$/i
            str_domains_self << "domain=#{params['searchdomain']}\n"
          end
        end

        params['localdomain'] = System::Hostname.domainname \
            unless params['localdomain']  =~ /\S/
        if params['localdomain'].respond_to? :strip!
          params['localdomain'].strip!
          if params['localdomain'] =~ /^[a-z0-9\.\-]+$/i
            str_domains_self << "local=/#{params['localdomain']}/\n"
          end
        end

        unless File.exists? CONFDIR + '/new'
          FileUtils.mkdir_p CONFDIR + '/new'
        end

        { # TODO: DRY: move some of this to write_local_domain(domain)
          'dns.conf' => str,
          'domains.self.conf' => str_domains_self
        }.each_pair do |filename, content|
          next if filename == 'dns.conf' and not params['nameservers']
          FileUtils.copy(CONFDIR + "/new/#{filename}", CONFDIR + "/new/#{filename}~") if
            File.exists? CONFDIR + "/new/#{filename}"
          File.open(CONFDIR + "/new/#{filename}",  'w') do |file|
            file.write content
          end
        end
        return {:ok => true}
      end

      def write_local_domain(domain)
        return if not domain
        filepath = CONFDIR + '/new/domains.self.conf'
        FileUtils.copy filepath, filepath + '~' if File.exists? filepath
        File.open(filepath, 'w') do |f|
          f.puts banner
          f.puts "domain=#{domain}"
          f.puts "local=/#{domain}/"
        end
      end

      def write_domains_conf_from_HTTP_request(params)
        lines = [banner]
        # only one checked-box is enough to block the domain
        blocked = []
        params['domains'].each do |domain|
          blocked |= [domain['name']] if domain['block'] == 'on'
        end
        params['domains'].each do |domain|
          domain['name'].strip!
          domain['name'].downcase!
          name = domain['name']
          next unless name =~ /^[\w\-\.]+$/
          ip    = domain['ip']
          valid_ip = OnBoard::Network::Interface::IP::valid_address? ip
          if blocked.include? name
            lines |= ["address=/#{name}/0.0.0.0"]
            lines |= ["address=/#{name}/::"]
          elsif valid_ip
            lines |= ["address=/#{name}/#{ip}"]
          end
        end

        unless File.exists? CONFDIR_CURRENT
          FileUtils.mkdir_p CONFDIR_CURRENT
        end

        dns_conf_file = "#{CONFDIR_CURRENT}/domains.conf"

        FileUtils.copy(dns_conf_file, "#{dns_conf_file}~" ) if
          File.exists? dns_conf_file
        File.open(dns_conf_file,  'w') do |file|
          lines.each{|line| file.puts line}
        end
        return {:ok => true}
      end

      def banner
        "# Generated by #{self.class.name}"
      end

      def write_host_records(h)
        file = "#{CONFDIR_CURRENT}/host_records.#{h[:table]}.conf"
        File.open file, 'w' do |f|
          f.puts banner
          if  Dnsmasq.version                                             and
              Dnsmasq.version >= Dnsmasq::REQUIRED_VERSION[:host_record]  and
              Dnsmasq.version != Dnsmasq::BAD_VERSION[:host_record]
            h[:records].each do |r|
              f.puts "host-record=#{r[:name]},#{r[:addr]}" # may be fqdn
            end
          else
            f.puts '#'
            f.puts "# Dnsmasq version #{Dnsmasq.version} (< #{Dnsmasq::REQUIRED_VERSION[:host_record]}) does not [properly] support --host-record"
          end
        end
      end

      def blocked?(domain)
        ips = @data['conf']['dns']['domains'][domain]
        ips.length > 0 and (ips - ['0.0.0.0', '::']  == [])
      end

      def block!(domain)
        @data['conf']['dns']['domains'][domain] = ['0.0.0.0', '::']
      end

      def restart
        self.class.restart
      end

    end
  end
end

