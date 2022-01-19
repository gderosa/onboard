require 'fileutils'

require 'onboard/system/process'
require 'onboard/network/interface'

class OnBoard
  module Network
    module AP

      # https://en.wikipedia.org/wiki/List_of_WLAN_channels
      CHANNELS = {
        2.4 => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
        5   => [
          32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62, 64, 66, 68,
          96, 100, 102, 104, 106, 108, 110, 112, 114, 116, 118, 120, 122, 124, 126, 128,
          132, 134, 136, 138, 140, 142, 144,
          149, 151, 153, 155, 157, 159, 161,
          165, 169, 173
        ]
      }

      def self.conffile(ifname)
        CONFDIR + '/new/' + ifname + '.conf'
      end

      def self.pidfile(ifname)
        File.join AP::VARRUN, "#{ifname}.pid"
      end

      def self.logfile(ifname)
        File.join AP::LOGDIR, "#{ifname}.log"
      end

      def self.set_config(ifname, params)
        configfile = conffile(ifname)
        File.open configfile, 'w' do |f|
          f.puts "# Auto-generated by #{self}"
          f.puts "interface=#{ifname}"
          %w{driver ssid channel country_code}.each do |k|
            v = params[k]
            f.puts "#{k}=#{v}" if v =~ /\S/
          end
          case params['mode']
          when 'a', 'b', 'g', 'ad'
            f.puts "hw_mode=#{params['mode']}"
          when 'n_5', 'n5'
            f.puts 'ieee80211n=1'
            f.puts 'hw_mode=a'
          when 'n_2.4', 'n2.4'
            f.puts 'ieee80211n=1'
            f.puts 'hw_mode=g'
          when 'ac'
            f.puts 'ieee80211ac=1'
            f.puts 'hw_mode=a'
          end
          if params['passphrase'].respond_to? :length and params['passphrase'].length > 0
            f.puts <<-EOF
# Use WPA authentication
auth_algs=1
# Use WPA2
wpa=2
# Use a pre-shared key
wpa_key_mgmt=WPA-PSK
# The network passphrase
wpa_passphrase=#{params['passphrase']}
EOF
          end
        end
        File.chmod 0600, configfile
      end

      def self.get_config(ifname)
        parse = {}
        res = {}
        unless File.exists? conffile(ifname)
          FileUtils.touch conffile(ifname)
        end
        File.readlines(conffile(ifname)).each do |line|
          if line =~ /^\s*([^#\s]+)\s*=\s*([^#\s]+)/  # Assuming no spaces in values.
            parse[$1.strip] = $2.strip  # Redundant, but in case we include spaces above...
          end
        end
        %w{driver ssid channel country_code wpa}.each do |k|
          res[k] = parse[k]
        end
        if parse['ieee80211ac'] == '1'
          res['mode'] = 'ac'
        elsif parse['ieee80211n'] == '1'
          if parse['hw_mode'] == 'g'
            res['mode'] = 'n_2.4'
          elsif parse['hw_mode'] == 'a'
            res['mode'] = 'n_5'
          end
        else
          res['mode'] = parse['hw_mode']
        end
        res['passphrase'] = parse['wpa_passphrase']
        return res
      end

      def self.start_stop(params)
        ifname = (params['ifname'] or params[:ifname])
        run = (params['run'] or params[:run])
        cmdline = "hostapd -B -P #{pidfile(ifname)} -t -f #{logfile(ifname)} #{conffile(ifname)}"
        if run
          if running?(params)
            return System::Command.run "kill -HUP #{pid(params)}", :sudo
          else
            return OnBoard::System::Command.run cmdline, :sudo
          end
        else
          if running?(params)
            return process(params).kill :sudo => true
          end
        end
      end

      def self.pid(params)
        ifname = params['ifname']
        if File.exists? pidfile(ifname)
          return File.read(pidfile(ifname)).to_i
        end
      end

      def self.process(params)
        return OnBoard::System::Process.new pid(params)
      end

      def self.running?(arg)
        # Hardo to DRY with self.pid() ...
        if arg.is_a? String
          ifname = arg
        else
          params = arg
          ifname = params['ifname']
        end
        if File.exists? pidfile(ifname)
          pid = File.read(pidfile(ifname)).to_i
          return (OnBoard::System::Process.running? pid) && pid
        else
          return false
        end
      end

      def self.save
        Dir.glob("#{AP::CONFDIR}/new/*.conf") do |conf_file|
          FileUtils.cp conf_file, AP::CONFDIR
          conf_file =~ /([^\/]+)\.conf$/
          ifname = $1
          run_persist_file = File.join AP::CONFDIR, "#{ifname}.run"
          if running?(ifname)
            FileUtils.touch run_persist_file
          elsif File.exists? run_persist_file
            FileUtils.rm run_persist_file
          end
        end
      end

      def self.restore
        Dir.glob("#{AP::CONFDIR}/*.conf") do |conf_file|
          FileUtils.cp conf_file, AP::CONFDIR + '/new/'
        end
        wlifs = Interface.getAll.select{|i| i.type == 'wi-fi'}
        wlifs.each do |iface|
          if File.exists? "#{AP::CONFDIR}/#{iface.name}.run"
            start_stop 'ifname' => iface.name, 'run' => true
          end
        end
      end
    end
  end
end
