require 'timeout'
require 'yaml'
require 'fileutils'

require 'onboard/network/interface/mac'
require 'onboard/network/interface/ip'
require 'onboard/network/bridge'
require 'onboard/hardware/lspci'
require 'onboard/hardware/lsusb'
require 'onboard/hardware/sdio'
require 'onboard/extensions/array.rb'

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
        }
      }

      # sort by muliple criteria
      # http://samdorr.net/blog/2009/01/ruby-sorting-with-multiple-sort-criteria/
      #
      # in practice, you are sorting an Enumerable made up of Arrays

      # First, order by type, according to a prefered order; then
      # order by name, but put interfaces with no MAC address at the end.
      PREFERRED_ORDER = lambda do |iface|
        [
          OnBoard::Network::Interface::TYPES[iface.type][:preferred_order],
          (iface.mac ? iface.name : "zzz_#{iface.name}")
      	]
      end

      # Class methods.

      class << self

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
            # TODO: take advantage of /master ([^: ]+)/          HERE--> vv   ???
            if line =~ /^(\d+): ([^: ]+): <(.*)> mtu (\d+) qdisc ([^: ]+).*state ([^: ]+)/
            # It might useful to know earlier which bridge the interface
            # belongs to (if it's part of a bridge, of course :).

              if netif_h                    # from the previous "parsing cycle"
                ary << self.new(netif_h)
                netif_h = nil
              end
              netif_h = {
                :n          => $1,
                :name       => $2,
                :misc       => $3.split(','), # es. %w{BROADCAST MULTICAST UP}
                :mtu        => $4,
                :qdisc      => $5,
                :state      => $6
              }
              #puts netif_h[:name] # DEBUG
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

          saved_ifaces.each do |saved_iface|
            current_iface = current_ifaces.detect {|x| x.name == saved_iface.name}
            unless current_iface
              if saved_iface.type == 'bridge'
                # bridge saved, not currently present: create it!
                Bridge.brctl 'addbr' => saved_iface.name
                current_ifaces = getAll
                redo
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
              if saved_iface.ipassign[:method] == :static and
                  current_iface.ipassign[:method] == :dhcp
                current_iface.stop_dhcp_client
              elsif current_iface.ipassign[:method] == :static and
                  saved_iface.ipassign[:method] == :dhcp
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

      attr_reader :n, :name, :misc, :mtu, :qdisc, :active, :state, :mac, :ip, :bus, :vendor, :model, :desc, :pciid, :preferred_metric
      attr_accessor :ipassign, :type, :wifi_properties

      include OnBoard::System

      def initialize(hash)
        %w{n name misc mtu qdisc active state type mac ip ipassign}.each do |property|
          eval "@#{property} = hash[:#{property}]"
        end

        ### HW detection
        if File.exists? "/sys/class/net/#{@name}/device"
          @modalias = File.read "/sys/class/net/#{@name}/device/modalias"
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

      def modify_from_HTTP_request(h)

        if h['preferred_metric']
          set_preferred_metric h['preferred_metric']
        end

        if h['active'] =~ /on|yes|1/
          #Command.run "ip link set #{@name} up", :sudo unless @active # DRY!
          ip_link_set_up unless @active
          if @ipassign[:method] == :static and h['ipassign']['method'] == 'dhcp'
            start_dhcp_client
          elsif @ipassign[:method] == :dhcp and h['ipassign']['method'] == 'static'
            stop_dhcp_client h['ipassign']['pid']
            assign_static_ips h['ip']
          elsif
              @ipassign[:method] == :static and h['ipassign']['method'] == 'static'
            assign_static_ips h['ip']
          end # if was dhcp and shall be dhcp... simply do nothing :-)
        elsif @active
          stop_dhcp_client h['ipassign']['pid'] if h['ipassign']['pid'] =~ /\d+/
          #flush_ip
          #Command.run "ip link set #{@name} down", :sudo # DRY!
          ip_link_set_down
        end
        if @ipassign[:method] == :static and h['ipassign']['method'] == 'static'
            assign_static_ips h['ip']
        end
        # if was dhcp and shall be dhcp... simply do nothing :-)
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
        if @preferred_metric =~ /\d/
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

      def stop_dhcp_client(pid=@ipassign[:pid])
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
        TYPES[@type.to_s][:human_readable] or @type.to_s
      end

      def to_h
        h = {}
        %w{name misc qdisc state type vendor model bus}.each do |property|
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

