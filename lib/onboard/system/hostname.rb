class OnBoard
  module System
    class Hostname # module? shall we have Hostname instances?

      CONFFILE_HOST   = File.join OnBoard::CONFDIR, 'hostname'
      CONFFILE_DOMAIN = File.join OnBoard::CONFDIR, 'domainname'

      class << self

        def get(arg=nil)
          case arg
          when :hostname
            `hostname`.strip
          when :domainname
            begin
              File.read(CONFFILE_DOMAIN).strip
            rescue Errno::ENOENT
              return nil
            end
          else
            get :hostname
          end
        end

        def set(arg)
          if arg.respond_to? :strip
            hostname_ = arg
          else
            hostname_, domainname_ = arg[:hostname], arg[:doainname] 
          end
          Command.send_command "hostname #{name.strip}", :sudo          if hostname_
          File.open( CONFFILE_DOMAIN, 'w' ){ |f| f.write domainname_ }  if domainname_
        end

        def hostname(name=nil)
          name ? set(name) : get
        end

        def domainname(name=nil)
          name ? set(:domainname => name) : get(:domainname)
        end

        def hostname=(n);   set :hostname => n;   end
        
        def domainname=(n); set :domainname => n; end
        
        def to_s
          hostname
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
