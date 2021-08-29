require 'timeout'
require 'yaml'
require 'json'
require 'fileutils'

require 'onboard/network/interface/mac'
require 'onboard/network/interface/ip'
require 'onboard/network/bridge'
require 'onboard/hardware/lspci'
require 'onboard/hardware/lsusb'
require 'onboard/hardware/sdio'
require 'onboard/extensions/array.rb'
require 'onboard/util'

class OnBoard
  module Network
    class Interface

      # Constants

      DHCPC_ATTEMPTS = [
        lambda{|ifname, metric_switch| System::Command.send_command  "dhcpcd5  -b  -p  #{metric_switch} #{ifname}", :sudo},
        lambda{|ifname, metric_switch| System::Command.send_command  "dhcpcd   -b  -p  #{metric_switch} #{ifname}", :sudo},
        lambda{|ifname, metric_switch| System::Command.bgexec        "dhcpcd       -p  #{metric_switch} #{ifname}", :sudo},
      ]

      TYPES = {
        'loopback'    => {
          :preferred_order  => 0,
          :human_readable   => 'Loopback'
        },
        'bridge'      => {
          :preferred_order  => 0.8,
          :human_readable   => 'Bridge'
        },
        'ether'       => {
          :preferred_order  => 1,
          :human_readable   => 'Ethernet'
        },
        'ether:usbmodem'       => {
          :preferred_order  => 1.5,
          :human_readable   => 'Ethernet (USB Modem)'
        },
        'wi-fi'       => {
          :preferred_order  => 2,
          :human_readable   => 'Wireless IEEE 802.11'
        },
        'ieee802.11'  => {
          :preferred_order  => 2.1, # "master"
          :human_readable   => 'IEEE 802.11 "master"'
        },
        'virtual'     => {
          :preferred_order  => 4,
          :human_readable   => 'Virtual Ethernet'
        },
        'P-t-P'       => {
          :preferred_order  => 5,
          :human_readable   => 'Point-to-Point'
        },
        'can' => {
          :preferred_order  => 6,
          :human_readable   => 'Controller Area Network'
        }
      }

      # sort by muliple criteria
      # http://samdorr.net/blog/2009/01/ruby-sorting-with-multiple-sort-criteria/
      #
      # in practice, you are sorting an Enumerable made up of Arrays

      # First, order by type, according to a prefered order; then
      # order by name, but put interfaces with no MAC address at the end.
      PREFERRED_ORDER = lambda do |iface|

        # Also, handle the case of possible new types:
        order_by_type = 9999
        if OnBoard::Network::Interface::TYPES[iface.type]
         order_by_type =  OnBoard::Network::Interface::TYPES[iface.type][:preferred_order]
        end

        return [
          order_by_type,
          (iface.mac ? iface.name : "zzz_#{iface.name}")
      	]
      end

      # Class methods.

      class << self

        include OnBoard::Util

        def getAll
          @@all_layer2 = getAll_layer2()
          @@all_layer3 = all_layer3(@@all_layer2)
          ary = []
          ary += @@all_layer3
          @@all_layer2.each do |netif|
            ary << netif unless ary.detect {|x| x.name == netif.name}
          end
          @@all_layer3.each do |netif|
            netif.get_preferred_metric!
          end
          return @@all = ary
        end
        alias get_all getAll # A bit of Ruby style... :-P

        def getAll_layer3
          return all_layer3(getAll_layer2())
        end

        def getAll_layer2

          ary = []
          netif_h = nil

          `ip addr show`.each_line do |line|
            if md = /^(\d+): ([^: ]+): <(.*)> mtu (\d+) qdisc ([^: ]+).*state ([^: ]+)/.match(line)
            # It might useful to know earlier which bridge the interface
            # belongs to (if it's part of a bridge, of course :).

              if netif_h                    # from the previous "parsing cycle"
                ary << self.new(netif_h)
                netif_h = nil
              end
              netif_h = {
                :n            => md[1],
                :displayname  => md[2],
                :name         => md[2].sub(/@[^@]+$/, ''),
                :misc         => md[3].split(','), # e.g. %w{BROADCAST MULTICAST UP}
                :mtu          => md[4],
                :qdisc        => md[5],
                :state        => md[6],
                :ip           => []
              }
              if netif_h[:state] == "UNKNOWN"
                if netif_h[:misc].include? "DOWN"
                  netif_h[:state] = "DOWN"
                else
                  carrier_file = "/sys/class/net/#{netif_h[:name]}/carrier"
                  unless File.readable? carrier_file
                    LOGGER.debug "waiting for #{carrier_file} ... "
                    begin
                      Timeout.timeout(6) do
                        until File.readable? carrier_file do
                          sleep 0.3
                        end
                      end
                    rescue Timeout::Error
                      LOGGER.warn "#{carrier_file} unavailable!"
                    end
                  end
                  if File.readable? carrier_file
                    carrier = File.read(carrier_file).strip
                    netif_h[:state] =
                      case carrier
                      when '0'
                        "NO-CARRIER"
                      when '1'
                        "UP"
                      else
                        "UNKNOWN"
                      end
                  end
                end
              end
              if netif_h[:misc].include_ary? %w{UP NO-CARRIER}
                netif_h[:state] = "NO-CARRIER"
              end
              if netif_h[:misc].include? "UP" or netif_h[:state] == "UP"
                netif_h[:active] = true
              else
                netif_h[:active] = false
              end
            else
              # puts line # DEBUG
            end
            if netif_h and line =~ /link\/(\S+) (([0-9a-f]{2}:){5}[0-9a-f]{2})?/
              netif_h[:type]  = $1  # This is where 'ether' is set as the @type, pretty much by default in most cases.
              netif_h[:mac]   = MAC.new $2 if $2
            end
            if line =~ /inet6? ([0-9a-f\.:]+)\/(\d{1,3}).*scope (\S+)/i
              # prepare the array of IP(v4/v6) addresses, if not present
              netif_h[:ip] = [] unless netif_h[:ip].respond_to? :<<
              netif_h[:ip] << IP.new(
                :addr       => $1,
                :prefixlen  => $2, # do not convert to_i
                :scope      => $3
              )
            elsif line =~ # Point-to-Point interface # TODO: or just TUN? Check!
                /inet6? ([0-9a-f\.:]+) peer ([0-9a-f\.:]+)\/(\d{1,3}).*scope (\S+)/i
              netif_h[:ip] = [] unless netif_h[:ip].respond_to? :<<
              netif_h[:ip] << IP.new(
                :addr       => $1,
                :scope      => $4,
                :peer       => IP.new(
                  :addr       => $2,
                  :prefixlen  => $3,
                  :scope      => $4
                )
              )
            end

            netif_h[:type] = "P-t-P" if netif_h[:misc].include? "POINTOPOINT"

          end
          ary << self.new(netif_h) if netif_h # fill in the last element
          # Now detect ip assigment method for each interface
          `ps -e -ww -o pid,cmd`.each_line do |line|
            if line =~ /^\s*(\d+)\s+(\S*(dhclient|dhcpcd|pump|udhcpc|ifplugd)[^\/\s]*)\s+(.*)$/
              pid             = $1
              cmd             = $2
              args            = $4.strip
              ifaces = ary.select do |i|
                args == i.name              or  # is        "eth0"
                args =~ /\s#{i.name}$/      or  # ends as   " eth0"
                args =~ /\s\-\w#{i.name}$/  or  # ends as   " -ieth0"
                args =~ /\s#{i.name}\s/     or  # contains  " eth0 "
                args =~ /\s\-\w#{i.name}\s/     # contains  " -ieth0 "
              end
              if ifaces.length > 1
                fail "fix your regexps: looks like a dhcp client process is managing more than one interface: #{ifaces.map{|i| i.name}.join}"
              end
              iface = ifaces[0]
              next unless iface
              iface.ipassign  = {
                :method         => :dhcp,
                :pid            => pid,
                :cmd            => cmd,
                :args           => args
              }
            end
          end

          # use iproute2 json output!
          ip_link_show_json_info = JSON.parse `ip -d -j link show`
          # 802.1Q VLANs
          ip_link_show_json_info.each do |ip_link_entry|
            ifname = ip_link_entry['ifname']
            if ip_link_entry['linkinfo'] and ip_link_entry['linkinfo']['info_kind'] and ip_link_entry['linkinfo']['info_kind'] == 'vlan'
              iface = ary.find{|iface| iface.name == ifname}
              iface.vlan_info[:ids] = [ip_link_entry['linkinfo']['info_data']['id']]
              iface.vlan_info[:link] = ip_link_entry['link']
              trunk_ifname = iface.vlan_info[:link]
              trunk_iface = ary.find{|iface| iface.name == trunk_ifname}
              trunk_iface.vlan_info[:is_trunk] = true
              trunk_iface.vlan_info[:ids] ||= []
              trunk_iface.vlan_info[:ids] << ip_link_entry['linkinfo']['info_data']['id']
            end
          end

          return @@all_layer2 = ary
        end

        def all_layer3(all_layer2=@@all_layer2)
          ary = []
          bridges, nonbridges = all_layer2.partition {|x| x.is_bridge?}

          (nonbridges.select {|x| x.type == 'wi-fi'}).each do |wifi|
            wifi.wifi_properties = {} unless wifi.wifi_properties
            # Prefer pciid over MAC addr to determine whether two
            # interfaces have the same underlying hardware
            wifi.wifi_properties['master'] = nonbridges.detect do |x|
              x.pciid == wifi.pciid and
              x.pciid =~ /\S/ and
              x.type == 'ieee802.11'
            end
          end

          ary += nonbridges.reject do |x|
            ['ieee802.11'].include? x.type or
            x.bridged_to # "bridged to anyone"
          end
          ary += bridges.map do |x|
            # create Bridge objects using generic Interface objects as templates
            br = OnBoard::Network::Bridge.new(x)
            br.stp = br.stp?  # this should be in _layer2 but still...
            # if one of the children interfaces is configured via DHCP, then
            # consider the bridge itself configured via DHCP and grab all the info
            if br.ipassign[:method] == :static
              br.members.each do |member_name|
                # NOTE: assumption: no more than ONE bridged iface has a dhcp (etc.)
                # client running.
                member = all_layer2.detect {|i| i.name == member_name}
                if member and member.ipassign[:method] != :static
                  br.ipassign = member.ipassign
                  break
                end
              end
            end
            br
          end
          return ary
        end

        def all_layer2
          begin
            if [ nil, false, [] ].include? @@all_layer2
              @@all_layer2 = getAll_layer2
            end
            return @@all_layer2
          rescue NameError
            return getAll_layer2
          end
        end

        # TODO: move to its own module?
        def set_802_1q_trunks(h)
          @@all_layer2 ||= getAll_layer2
          h.each_pair do |name, vlan_ids|
            iface = @@all_layer2.find{|netif| netif.name == name}
            # vlan_ids can be e.g. "1, 2, 44" or [1, 2, 44] etc.: normalize!
            vlan_ids = vlan_ids.split(/[,\s]+/) if vlan_ids.respond_to? :split
            vlan_ids.map!{|x| x.to_i}
            to_add    = vlan_ids - iface.vlan_info[:ids]
            to_remove = iface.vlan_info[:ids] - vlan_ids
            to_add.each do |vlan_id|
              # e.g. "eth0.VLAN-002"
              vifname = name + '.VLAN-' + '%03d' % vlan_id
              # See e.g. https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-configure_802_1q_vlan_tagging_using_the_command_line#sec-Configure_802_1Q_VLAN_Tagging_ip_Commands
              System::Command.run "ip link add link #{name} name #{vifname} type vlan id #{vlan_id}", :sudo
              # No reason not to bring it UP... (DOWN by default)
              System::Command.run "ip link set up dev #{vifname}", :sudo
            end
            to_remove.each do |vlan_id|
              viface = @@all_layer2.find{|viface| viface.vlan_info[:link] == name and viface.vlan_info[:ids] == [vlan_id]}
              System::Command.run "ip link delete #{viface.name}", :sudo
            end
          end
        end

        def save
          self_getAll = self.getAll
          File.open(OnBoard::CONFDIR + '/network/interfaces.yml', 'w') do |f|
            YAML.dump self_getAll, f
          end
          #File.open(OnBoard::CONFDIR + '/network/interfaces.dbg.yaml', 'w') do |f|
          #  YAML.dump self_getAll, f
          #end
        end

        def restore(opt_h={})
          saved_ifaces = []

          if opt_h[:saved_interfaces]
            saved_ifaces = opt_h[:saved_interfaces]
          else
	          begin
              File.open(
                  OnBoard::CONFDIR + '/network/interfaces.yml', 'r') do |f|
                saved_ifaces =  YAML.load f
              end
            rescue # invalid or non-existent dat file? skip!
              return
            end
          end
          if opt_h[:current_interfaces]
            current_ifaces = opt_h[:current_interfaces]
          else
            current_ifaces = getAll
          end

          # VLANs
          restore_trunks = {}
          saved_ifaces.each do |saved_iface|
            next unless saved_iface.respond_to? :vlan_info and saved_iface.vlan_info.respond_to? :[]
            parent_ifname = saved_iface.vlan_info[:link]
            vlan_id = saved_iface.vlan_info[:ids][0]
            if parent_ifname and vlan_id
              restore_trunks[parent_ifname] ||= []
              restore_trunks[parent_ifname] << vlan_id
            end
          end
          set_802_1q_trunks restore_trunks
          # end VLANS

          saved_ifaces.each do |saved_iface|
            current_iface = current_ifaces.detect {|x| x.name == saved_iface.name}
            unless current_iface
              if saved_iface.type == 'bridge'
                # bridge saved, not currently present: create it!
                Bridge.brctl 'addbr' => saved_iface.name
                current_ifaces = getAll
                redo
              elsif saved_iface.type =~ /^ether/
                LOGGER.info "restore: waiting for interface #{saved_iface.name} to show up..."
                wait_for sleep: 1, timeout: 25 do
                  current_ifaces = getAll
                  current_iface = current_ifaces.detect {|x| x.name == saved_iface.name}
                  unless current_iface
                    LOGGER.debug "restore: interface #{saved_iface.name} not detected yet, retrying..."
                  end
                  current_iface
                end
                if current_iface
                  LOGGER.info "restore: interface #{saved_iface.name} found"
                  redo
                else
                  LOGGER.error "restore: waiting for interface #{saved_iface.name} has reached time out :("
                  next
                end
              else
                next
              end
            end
            if saved_iface.active and not current_iface.active
              current_iface.ip_link_set_up
            elsif !saved_iface.active and current_iface.active
              current_iface.ip_link_set_down
            end
            if saved_iface.type == 'bridge' and current_iface.type == 'bridge'
              if saved_iface.stp
                Bridge.brctl({
                  'stp' => {
                    current_iface.name => 'on'
                  }
                })
              end

              to_add    = saved_iface.members_saved - current_iface.members
              to_remove = current_iface.members - saved_iface.members_saved
              # Bridge.brctl was meant to get HTTP POST/PUT params,
              # hence its strange syntax.
              to_add.each do |member_if|
                Bridge.brctl({
                    'addif' => {
                        current_iface.name => {member_if => true}
                    }
                })
              end
              to_remove.each do |member_if|
                Bridge.brctl({
                    'delif' => {
                        current_iface.name => {member_if => true}
                    }
                })
              end
            end
            if saved_iface.active
              # Stop dhcp if saved as static, restart anyway if saved as dhcp.
              # Restarting/refreshing dhcp client is needed, among other things, to set route metrics.
              if current_iface.ipassign[:method] == :dhcp
                current_iface.stop_dhcp_client
              end
              if saved_iface.ipassign[:method] == :dhcp
                current_iface.start_dhcp_client
              end
            end
          end
          # update our knowledge of IP addresses, after some interfaces may
          # have been brought up/down
          current_ifaces = getAll
          saved_ifaces.each do |saved_iface|
            current_iface = current_ifaces.detect {|x| x.name == saved_iface.name}
            next unless current_iface # avoid NoMethodError if iface no longer
                # exists
            if saved_iface.ipassign[:method] == :static
              current_iface.assign_static_ips saved_iface.ip
            end
            current_iface.set_preferred_metric saved_iface.preferred_metric if saved_iface.preferred_metric
          end
        end


      end

      # Instance methods and attributes.

      attr_reader :n, :displayname, :name, :vlan_info, :misc, :mtu, :qdisc, :active, :state, :mac, :ip, :bus, :vendor, :model, :desc, :pciid, :preferred_metric
      attr_accessor :ipassign, :type, :wifi_properties, :vlan_info

      include OnBoard::System

      def initialize(hash)
        %w{n displayname name misc mtu qdisc active state type mac ip ipassign}.each do |property|
          eval "@#{property} = hash[:#{property}]"
        end

        @vlan_info = {
          is_trunk: false,
          ids: []
        }

        ### HW detection
        if File.exists? "/sys/class/net/#{@name}/device"
          @modalias = (File.read "/sys/class/net/#{@name}/device/modalias").strip
          @modalias =~ /^(\w+):/
          @bus = $1
          if @bus == 'pci'
            set_pciid_from_sysfs
            lspci_by_id = OnBoard::Hardware::LSPCI.by_id
            if @pciid
              @desc = lspci_by_id[@pciid][:desc]
              @vendor =lspci_by_id[@pciid][:vendor]
              @model = lspci_by_id[@pciid][:model]
            end
          elsif @bus == 'usb'
            @modalias =~ /^usb:v([0-9A-F]+)p([0-9A-F]+)/
            @vendor_id = $1.downcase
            @model_id = $2.downcase
            lsusb = Hardware::LSUSB.new :vendor_id => @vendor_id, :model_id => @model_id
            @vendor = lsusb.vendor
            @model = lsusb.model
          elsif @bus == 'sdio'
            @modalias =~ /^sdio:.*v([0-9A-F]+).*d([0-9A-F]+)/
            @vendor_id = $1.downcase
            @model_id = $2.downcase
            @vendor, @model = Hardware::SDIO::vendormodel_from_ids @vendor_id, @model_id
          end
        elsif @type == 'ether'
          @type = 'virtual'  # virtual ethernet, tap etc.
        end

        if @type == 'P-t-P'
          @ipassign = {:method => :pointopoint}
        elsif @type == 'ieee802.11' # wireless 'masters' don't get IP
           @ipassign = {:method => :none}
        elsif [nil, false, '', 0].include? @ipassign
          @ipassign = {:method => :static}
        end

        if @type == 'ether'
          if (
            File.exists? "/sys/class/net/#{@name}/phy80211" or
            File.exists? "/sys/class/net/#{@name}/wireless"
          )
            @type = 'wi-fi'
          elsif File.basename(File.readlink "/sys/class/net/#{@name}/device/driver") == 'cdc_ether'
            # TODO: add other drivers?
            # NOTE: used so far for "HiLink" Huawei mobile modems
            @type = 'ether:usbmodem'
          end
        end
      end

      def to_s
        name
      end

      def is_bridge?
        bridgedir = "/sys/class/net/#{@name}/bridge"
        if Dir.exists? bridgedir
          @type = 'bridge'
          return true
        else
          return false
        end
      end

      def bridge?; self.is_bridge?; end

      def bridged_to
        bridgelink = "/sys/class/net/#@name/brport/bridge"
        if File.symlink? bridgelink
          return File.basename( File.readlink(bridgelink) )
        elsif File.exists? bridgelink
          raise RuntimeError, "#{bridgelink} should be a symlink!"
        else
          return nil
        end
      end

      def bridged?; bridged_to; end

      def is_bridged?; bridged_to; end

      def set_preferred_metric(_preferred_metric)
        # TODO: use tmpfs?
        metrics_dir = OnBoard::CONFDIR + '/network/interfaces/preferred_metrics/new'
        metric_file = metrics_dir + '/' + @name
        @preferred_metric = _preferred_metric
        FileUtils.mkdir_p metrics_dir
        File.open(metric_file, 'w') do |f|
          f.write @preferred_metric.to_s
        end
      end

      def get_preferred_metric!
        # gets from file but set in the object!
        metrics_dir = OnBoard::CONFDIR + '/network/interfaces/preferred_metrics/new'
        metric_file = metrics_dir + '/' + @name
        if File.exists? metric_file
          File.open(metric_file, 'r') do |f|
            metric_data = f.read
            if metric_data =~ /\d/
              @preferred_metric = metric_data.to_i
            else
              @preferred_metric = metric_data.to_s
            end
          end
        end
      end

      def modify_from_HTTP_request(h, opts={})
        if h['preferred_metric']
          set_preferred_metric h['preferred_metric']
        end

        if h['active']
          ip_link_set_up unless @active
        elsif @active and (h['active'] == false or not opts[:safe_updown])
          # In browser context, a checkbox param ^^ is simply absent (null/nil) for "unchecked".
          # In (JSON) API context, we want h['active'] to be false explicitly, before bringing a network interface down!
          # See also controller/network/interfaces.rb
          ip_link_set_down
        end

        if h['ipassign'].respond_to? :[]
          if @ipassign[:method] == :static and h['ipassign']['method'] == 'dhcp'
            start_dhcp_client
          elsif @ipassign[:method] == :dhcp and h['ipassign']['method'] == 'static'
            stop_dhcp_client h['ipassign']['pid']
            assign_static_ips h['ip']
          elsif @ipassign[:method] == :dhcp and h['ipassign']['method'] == 'dhcp'
            if ['on', true].include? h['ipassign']['renew']
              stop_dhcp_client h['ipassign']['pid']
              start_dhcp_client
            end
          elsif @ipassign[:method] == :static and h['ipassign']['method'] == 'static'
            assign_static_ips h['ip']
          end
        end
      end

      def has_ip?(ipobj)
          @ip ? (@ip.detect {|x| x == ipobj}) : nil
      end

      def ip_addr_add(ip)
        return false if @ipassign[:method] != :static
        Command.run "ip addr add #{ip.addr.to_s}/#{ip.prefixlen} dev #@name", :sudo
      end

      def ip_addr_del(ip)
        return false if @ipassign[:method] != :static
        Command.run "ip addr del #{ip.addr.to_s}/#{ip.prefixlen} dev #@name", :sudo
      end

      def ip_link_set_up
        return false if not [:static, :dhcp].include? @ipassign[:method]
        Command.run "ip link set #{@name} up", :sudo
      end

      def ip_link_set_down
        return false if not [:static, :dhcp].include? @ipassign[:method]
        Command.run "ip link set #{@name} down", :sudo
      end

      def flush_ip
        return false if not [:static, :dhcp].include? @ipassign[:method]
        Command.run("ip addr flush dev #{@name}", :sudo) if
            @ip.respond_to? :[] and @ip.length > 0
      end
      alias ip_addr_flush flush_ip

      def dhcpcd_metric_switch
        if @preferred_metric.is_a? Integer or @preferred_metric =~ /\d/
          return "-m #{@preferred_metric}"
        end
        return ''
      end

      def start_dhcp_client
        success = nil
        DHCPC_ATTEMPTS.each do |lmbda|
          success = lmbda.call @name, dhcpcd_metric_switch
          break if success
        end
        sleep(0.1) # horrible
        return success
      end

      def stop_dhcp_client(pid=nil)
        # Sometimes it's actually called with a nil arg, so just setting a default is not enough
        pid = @ipassign[:pid] unless pid and pid != 0
        Command.run "kill #{pid}", :sudo # apparently dhcpcd --release #{@name} is useless...
      end

      def assign_static_ips(ipStringHash_or_ipObjArray)
        ipStringHash = case ipStringHash_or_ipObjArray
                       when Hash
                         ipStringHash_or_ipObjArray
                       when Array
                         IP.ary_to_StringHash(ipStringHash_or_ipObjArray)
                       else
                         nil
                       end
        return unless ipStringHash
        oldIPs = ip() ? ip() : []
        newIPs = []
        ipStringHash.each_value do |ipString|
          begin
            newIPs << self.class::IP.new(ipString)
          rescue ArgumentError
          end
        end
        oldIPs.each do |oldip|
          unless newIPs.find {|newip| newip == oldip}
            ip_addr_del(oldip)
          end
        end
        newIPs.each do |newip|
          unless oldIPs.find {|oldip| oldip == newip}
            ip_addr_add(newip)
          end
        end
      end

      def type_hr
        if TYPES[@type.to_s]
          return TYPES[@type.to_s][:human_readable]
        else
          return @type.to_s
        end
      end

      def to_h
        h = {}
        %w{name misc qdisc state type vendor model bus vlan_info}.each do |property|
          h[property] = eval "@#{property}" if eval "@#{property}"
        end
        h['active']   = @active   # may be true or false
        %w{n mtu}.each do |property|
          h[property] = (eval "@#{property}").to_i
        end
        %w{mac}.each do |property|
          h[property] = (eval "@#{property}") if eval "@#{property}"
        end
        h['ip'] = @ip
        h['ipassign'] = {
          'method'      => @ipassign[:method].to_s,
          'pid'         => @ipassign[:pid].to_i,
          'cmd'         => @ipassign[:cmd],
          'args'        => @ipassign[:args]
        }
        h['wifi_properties'] = @wifi_properties
        return h
      end
      alias data to_h

      def to_json(*a); to_h.to_json(*a); end
      # def to_yaml(*a); to_h.to_yaml(*a); end # save as object

      private

      def set_pciid_from_sysfs
        ["/sys/class/net/#@name", "/sys/class/net/#@name/device"].each do |path|
          if File.symlink? path
            if File.readlink(path) =~
                /devices\/pci....:..\/.*:(..:..\..)/
                # matches something like:
                # ../../devices/pci0000:00/0000:00:1e.0/0000:02:0e.0/ssb0:0/net/eth0
                # capturing "02:0e.0"                        ^^^^^^^
              @pciid = $1
            end
          else
            @pciid = nil
          end
        end
      end

    end
  end
end

