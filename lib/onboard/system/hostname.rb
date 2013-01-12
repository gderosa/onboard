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

        def be_resolved(*opts)
          dnsmasq = Network::Dnsmasq.new
          addresses = Network::Interface.get_all.map{|i| i.ip.first.addr}
          records = []
          addresses.each do |addr|
            if addr === '127.0.0.1' and hostname != 'localhost'
              records << {:addr => addr, :name => 'localhost'}  
            end
            records << {:addr => addr, :name => hostname}
          end

          # This leads to permission issues: --addn-hosts file is read *after*
          # dnsmasq has lost root privileges
          # dnsmasq.write_addn_hosts :data => hosts_h, :table => :hosts_self
          #
          # An approach based on --interface-name is problematic as well, 
          # 'cause --localise-queries behavior doesn't apply.
          #
          # So an approach based on --host-record is chosen. Limitation: 
          # if ip addresses change, Dnsmasq#write_host_records need to be called
          # again (and dnsmasq daemon restarted again...) 
          dnsmasq.write_host_records :records => records, :table => :self
          dnsmasq.restart unless opts.include? :no_restart
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
