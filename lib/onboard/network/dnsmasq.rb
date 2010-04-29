require 'fileutils'

require 'onboard/network/interface/ip'
require 'onboard/platform/debian'

class OnBoard
  module Network
    class Dnsmasq
      CONFDIR = OnBoard::CONFDIR + '/network/dnsmasq'

      def self.save
        %w{dnsmasq.conf dhcp.conf dns.conf}.each do |file|
          FileUtils.copy "#{CONFDIR}/new/#{file}", "#{CONFDIR}/#{file}"
        end
      end

      # "#{CONFDIR}"            # saved configuration
      # "#{CONFDIR}/new"        # current configuration
      # "#{CONFDIR}/defaults"   # "factory" defaults
      def self.restore
        OnBoard::System::Command.run "mkdir -p #{CONFDIR}/new"
        %w{dnsmasq.conf dhcp.conf dns.conf}.each do |file|
          unless File.exists? "#{CONFDIR}/#{file}"
            FileUtils.copy "#{CONFDIR}/defaults/#{file}", "#{CONFDIR}/"
          end
          FileUtils.copy "#{CONFDIR}/#{file}", "#{CONFDIR}/new/#{file}"
        end
        # 'new' subdirectory is always the current config dir
        # do not copy new/*.conf to parent directory if you don't want
        # persistence        
        OnBoard::PLATFORM::restart_dnsmasq("#{CONFDIR}/new")
      end

      def self.validate_dhcp_range(dhcp_range_params)
        begin
          return {:ignore => true} if 
              dhcp_range_params['delete'] =~ /on|yes|true|1/i
        rescue
          pp dhcp_range_params
          exit
        end

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
              'localdomain' => ''
            }
          },
          'leases'      => [],
          'resolvconf'  => {  # tipically obtained via DHCP (appliance may be DHCP client on the external/WAN interface, and DHCP server on the internal/LAN interface)
            'file'        => '/etc/resolv.conf',
            'nameservers' => []  
          }
        }
      end

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
      def parse_dns_conf
        return false unless File.readable? CONFDIR + '/new/dns.conf'
        File.open CONFDIR + '/new/dns.conf' do |file|
          file.each_line do |line|
            next if line =~ /^\s*#/
            line.strip!
            # The following regexes are too 'rigid' to parse conf file 
            # not written by ourselves, but should be ok for our needs.
            if line =~ /^\s*server\s*=\s*([^,\s#]+)\s*#\s?(.*)$/
              @data['conf']['dns']['nameservers'] << {
                'ip'      => $1,
                'comment' => $2
              }
            elsif line =~ /^\s*server\s*=\s*([^,\s#]+)/
              @data['conf']['dns']['nameservers'] << {
                'ip'      => $1,
                'comment' => ''
              }
            elsif line =~ /^\s*domain\s*=\s*([^,\s#]+)/
              @data['conf']['dns']['searchdomain'] << $1
            elsif line =~ /^\s*local\s*=\s*\/([^,\s#]+)\//
              @data['conf']['dns']['localdomain'] << $1
            end
          end
        end
      end

      def parse_dns_cmdline
        # NOTE: it's assumed only one dnsmasq instance at a time
        # NOTE: the only option parsed is -r
        if File.read("/proc/#{`pidof dnsmasq`.strip}/cmdline") =~ /-r\0([^\0]+)/
          @data['resolvconf']['file'] = $1
        end         
        File.open @data['resolvconf']['file'] do |file|
          file.each_line do |line|
            if line =~ /^\s*nameserver\s+(\S+)/
              @data['resolvconf']['nameservers'] << $1
            end
          end
        end
      end

      def write_dhcp_conf_from_HTTP_request(params) 
        str = ''
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
        params['hosts'].each_value do |host|
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

      def write_dns_conf_from_HTTP_request(params)
        str = "# Automatically generated by #{self.class.name} \n\n"
        params['nameservers'].each do |ns|
          ns['ip'].strip!
          next if not \
              OnBoard::Network::Interface::IP::valid_address? ns['ip']  
          str << "server=#{ns['ip']} # #{ns['comment']}\n" 
        end
        str << "\n"

        params['searchdomain'].strip!
        if params['searchdomain'] =~ /^[a-z0-9\.\-]+$/i
          str << "domain=#{params['searchdomain']}\n" 
        end

        params['localdomain'].strip!
        if params['localdomain'] =~ /^[a-z0-9\.\-]+$/i
          str << "local=/#{params['localdomain']}/\n"
        end

        FileUtils.copy(CONFDIR + '/new/dns.conf', CONFDIR + '/new/dns.conf~')
        File.open(CONFDIR + '/new/dns.conf',  'w') do |file|
          file.write str
        end
        return {:ok => true} 
        # just like we did for interface IP addresses, sending an invalid edit
        # (for example the empty string) is the way to remove an item.
      end

    end
  end
end

