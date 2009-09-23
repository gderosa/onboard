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

      def self.restore
        OnBoard::System::Command.run "mkdir -p #{CONFDIR}/new"
        %w{dnsmasq.conf dhcp.conf dns.conf}.each do |file|
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
          'conf'=> {
            'dhcp' => {
              'ranges' => [],
              'fixed-hosts' => []
            }
          },
          'leases' => []
        }
      end

      def parse_dhcp_conf
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
            if line =~ /dhcp-leasefile=(\S+)/ # TODO? handle flepath w/ spaces?
              dhcp_leasefile = $1
              break
            end   
          end
        end
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
        FileUtils.copy(CONFDIR + '/new/dhcp.conf', CONFDIR + '/new/dhcp.conf~')
        File.open(CONFDIR + '/new/dhcp.conf',  'w') do |file|
          file.write str
        end
        return {:ok => true} 
      end

    end
  end
end

