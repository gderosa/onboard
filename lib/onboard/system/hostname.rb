class OnBoard
  module System
    class Hostname # module? shall we have Hostname instances?

      CONFFILE_HOST   = File.join OnBoard::CONFDIR, 'hostname'
      CONFFILE_DOMAIN = File.join OnBoard::CONFDIR, 'domainname'

      class NoDomainName  < RuntimeError; end
      class NoHostName    < RuntimeError; end

      class << self

        def get(arg=nil)
          case arg
          when :hostname
            # return nil if hostname command gives no output
            hostname_ = `hostname`.strip
            hostname_ if hostname_.length > 0
          when :domainname
            # return nil if file does not exist, is empty or contains just
            # spaces or newlines
            begin
              domainname_ =   File.read(CONFFILE_DOMAIN).strip
              domainname_ =   nil unless domainname_.length > 0
            rescue Errno::ENOENT
            ensure
              # domainname_ ||= guess :domainname, :via => :all_fqdns
              return domainname_ ||= nil
            end
          else
            get :hostname
          end
        end

=begin
        def guess(what=:hostname, opts={:via=>:all_fqdns})
          fqdn_h = {:hostname => nil, :domainname => nil}

          case opts[:via]
          when :all_fqdns
            `hostname --all-fqdns`.split.each do |fqdn|
              fqdn.strip!
              if /^([^\.]+)\.([^\.]+.*)$/ =~ fqdn
                fqdn_h = {:hostname => $1, :domainname => $2}
                break
              elsif !fqdn_h[:hostname]
                fqdn_h[:hostname] = fqdn
              end
            end
          end

          case what
          when :fqdn
            fqdn_h[:hostname] + '.' + fqdn_h[:domainname]
          else
            fqdn_h[what]
          end
        end
=end

        # Make a dns reverse query on machine network interface primary
        # addresses
        # # TODO: timeout, cache ...
        def all_fqdns
          `hostname --all-fqdns`.split.uniq.sort do |a, b|
            # first, the "configured" fqdn
            if    a == fqdn and b != fqdn
              -1
            elsif a != fqdn and b == fqdn
              +1
            else
              # order alphanumerically but group by domains and subdomains
              a.split('.').reverse <=> b.split('.').reverse
            end
          end
        end

        def fqdn_match_dns?
          begin
            all_fqdns.size == 1 and all_fqdns.first == fqdn
          rescue NoHostName, NoDomainName
          end
        end

        def set(arg)
          if arg.respond_to? :strip
            hostname_ = arg
          else
            hostname_, domainname_ = arg[:hostname], arg[:domainname]
          end
          Command.send_command "hostname #{hostname_.strip}", :sudo     if hostname_
          File.open( CONFFILE_DOMAIN, 'w' ){ |f| f.write domainname_ }  if domainname_
        end

        # Act like the hostname Unix command
        def hostname(name=nil)
          name ? set(name) : get
        end

        def domainname(name=nil)
          name ? set(:domainname => name) : get(:domainname)
        end

        def hostname=(n);   set :hostname => n;   end

        def domainname=(n); set :domainname => n; end

        def fqdn(*opts)
          if opts.include? :raise
            raise NoDomainName  unless domainname
            raise NoHostName    unless hostname
          end
          answer = "#{hostname}.#{domainname}"
          class << answer
            def match_dns?
              Hostname.fqdn_match_dns?
            end
          end
          answer
        end

        def to_s
          hostname
        end

        def to_h
          {
            'host' => hostname,
            'domain' => domainname,
            'all_fqdns' => all_fqdns
          }
        end

        def to_json(*a)
          to_h.to_json(*a)
        end

        def be_resolved(*opts)
          dnsmasq = Network::Dnsmasq.new
          # TODO: NOTE: this is HORRIBLE!
          addresses = Network::Interface.get_all.\
map{|iface| iface.ip}.flatten.compact.map{|ip| ip.addr}.select{|addr| addr.private_ip?}
          records = []
          addresses.each do |addr|
            if addr === '127.0.0.1' and hostname != 'localhost'
              records <<  {
                :addr       => addr,
                :name       => 'localhost'
              }
              records <<  {
                :addr       => addr,
                :name       => "localhost.#{domainname}"
              } if domainname
            end
            records << {
              :addr       => addr,
              :name       => fqdn
            } if hostname and domainname
            records << {
              :addr       => addr,
              :name       => hostname
            } if hostname
          end
          # Relying on --addn-hosts leads to permission issues:
          # --addn-hosts file is read *after* dnsmasq has lost root privileges
          #
          # An approach based on --interface-name is problematic as well,
          # 'cause --localise-queries behavior doesn't apply.
          #
          # So: an approach based on --host-record is chosen. Limitation:
          # if ip addresses change, Dnsmasq#write_host_records need to be called
          # again (and dnsmasq daemon restarted again...)
          dnsmasq.write_host_records :records => records, :table => :self
          dnsmasq.write_local_domain domainname if domainname
          dnsmasq.restart unless opts.include? :no_restart
        end

        alias be_resolvable be_resolved

        def save
          # domain name file is already "saved"
          File.open(CONFFILE_HOST, 'w') {|f| f.write hostname}
        end

        def restore
          # setting thedomain name is a matter of network administration (dns),
          # not local system administration...
          hostname File.read CONFFILE_HOST if File.exists? CONFFILE_HOST
        end

      end

    end
  end
end
