class OnBoard
  module System
    class Hostname # module? shall we have Hostname instances?

      CONFFILE = File.join OnBoard::CONFDIR, 'hostname'
      
      class << self

        def get
          `hostname`.strip
        end

        def set(name)
          Command.send_command "hostname #{name.strip}", :sudo
        end

        def hostname(name=nil)
          name ? set(name) : get
        end

        def be_resolved
          dnsmasq = Network::Dnsmasq.new
          addresses = Network::Interface.get_all.map{|i| i.ip.first.addr}
          records = []
          addresses.each do |addr|
            if addr === '127.0.0.1' and hostname != 'localhost'
              records << {:addr => addr, :name => 'localhost'}  
            end
            records << {:addr => addr, :name => hostname}
          end
          # dnsmasq.write_addn_hosts :data => hosts_h, :table => :hosts_self
          dnsmasq.write_host_records :records => records, :table => :self
          dnsmasq.restart
        end

        def save
          File.open(CONFFILE, 'w') {|f| f.write hostname}
        end

        def restore
          hostname File.read CONFFILE
        end

      end

    end
  end
end
