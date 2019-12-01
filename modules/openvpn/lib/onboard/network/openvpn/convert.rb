autoload :IPAddr, 'ipaddr'

class OnBoard
  module Network
    module OpenVPN
      module Convert

        module_function

        def textarea2push_routes(text, metric=nil)
          if metric
            # an empty of space-only string should bring to default
            unless metric =~/\S/
              metric = nil
            end
          end
          out = ''
          push_routes = text.lines.map{|x| x.strip}
          push_routes.each do |push_route|
            # Translate "10.11.12.0/24" -> "10.11.12.0 255.255.255.0"
            begin
              ip = IPAddr.new(push_route)
            rescue ArgumentError
              next
            end
            out << %Q{push "route #{ip} #{ip.netmask} vpn_gateway #{metric or DEFAULT_METRIC}"}
            out << "\n"
          end
          return out
        end

        # Warning: html escape is not performed!
        def routes2textarea(h_ary)
          return '' unless h_ary.respond_to? :each
          out = ''
          h_ary.each do |route_h|
            # out << route_h.pretty_inspect
            if route_h['net'] and route_h['mask']
              out << route_h['net'] << '/' << route_h['mask'] << "\n"
            end
          end
          return out
        end

        # Turn the OpenVPN command line into a "virtual" configuration file
        def cmdline2conf(cmdline_ary)
          line_ary = []
          text = ""
          cmdline_ary.each do |arg|
            if arg =~ /\-\-(\S+)/
              text << line_ary.join(' ') << "\n" if line_ary.length > 0
              line_ary = [$1]
            elsif line_ary.length > 0
              line_ary << arg
            end
          end
          text << line_ary.join(' ') << "\n" if line_ary.length > 0
          return text
        end

      end
    end
  end
end

