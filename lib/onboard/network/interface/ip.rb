require 'socket'
require 'forwardable'

require 'onboard/extensions/ipaddr'

# NOTE: the IPAddr std class cannot store the host AND the network IP address.
# For example:
#
# ipaddr1 = IPAddr.new "192.168.1.2/24"
#
# and
#
# ipaddr2 = IPAddr.new "192.168.1.0/24"
#
# are equal.
#
# With some degree of redundancy, IPAddrExt class stores *three* IPAddr
# objects: @addr, @net and @netmask. There shouldn't be performance 
# problems since no router|server|appliance is supposed to have thousands
# of IP addresses configuerd. For routing table entries, anyway, simple IPAddr
# objects will be sufficent.

class OnBoard
  module Network
    class Interface
      class IP

        attr_reader :addr, :prefixlen, :scope, :net, :netmask, :af, :peer

        def initialize(arg)
          case arg

          when Hash
            h = arg 
            @addr       = IPAddr.new h[:addr]  
            if h[:prefixlen]
              @prefixlen  = h[:prefixlen].to_i           
            else
              @prefixlen  = @addr.prefixlen # /32 or /128
            end 
            @scope      = h[:scope]               
            @net        = @addr.mask(@prefixlen)  
              # returns the masked ip, not the mask
            # Point-to-Point connection
            if h[:peer].kind_of? Hash
              @peer = IP.new h[:peer]
            elsif h[:peer].kind_of? IP
              @peer = h[:peer]
            else
              @peer = nil
            end

          when String
            str = arg.strip
            h = self.class.parse_string str
            if h
              ip = h[:ip] 
              prefixlen = h[:prefixlen]  
              @addr         = IPAddr.new ip
              if prefixlen
                @prefixlen  = prefixlen.to_i
              else
                case @addr.family
                when Socket::AF_INET
                  32
                when Socket::AF_INET6
                  128
                else
                  raise RuntimeError, "@addr.family should be Socket::AF_INET or Socket::AF_INET6 ; something went wrong when creating the IPAddr object"
                end
              end
              @scope        = "global?"
              @net          = IPAddr.new str
            else
              raise ArgumentError, "#{str} is not a valid IPv4 or IPv6 address in CIDR notation. "
            end
          
          else
            raise TypeError, "Initialization argument for class #{self.class.name} must be a String or an Hash - got #{arg.class.name} instead."   

          end

          @netmask    = @net.netmask            
            # returns the netmask as an IPAddr
          @af         = case @addr.family # Socket::AF_* are Fixnum
                            when Socket::AF_INET
                              :inet
                            when Socket::AF_INET6
                              :inet6
                        end         
        end

        def ==(other)
          return false unless other # this cannot be equal to nil or false
          @addr == other.addr and @prefixlen == other.prefixlen
        end

        extend ::Forwardable
        def_delegators :@addr, :loopback?, :multicast?, :link_local?

        def to_h
          h       = {}
          %w{addr}.each do |p| # net and netmask are redundant (see prefixlen)
            h[p]  = (eval "@#{p}").to_s
          end
          %w{prefixlen scope}.each do |p|
            h[p]  = (eval "@#{p}") 
          end
          h['af'] = @af.to_s 
          if @peer
            h['peer'] = @peer.data
          end
          return h
        end
        alias data to_h

        def to_json(*a); to_h.to_json(*a); end
        # def to_yaml(*a); to_h.to_yaml(*a); end # save as an object!

        # Detection of invalid IP addresses is too SLOW in the standard 
        # IPAddr library, so we implemented our own check. # TODO such a
        # duplicated effort is a pity # TODO: rewrite a better IPAddr?
        #
        def self.parse_string(str)
          str.strip!
          if str =~ /(.*)\/(\d+)/  # prefixlen specified
            addr, prefixlen = $1, $2
            proto = self.valid_address?(addr)
            case proto
            when :ipv4
              return false if prefixlen.to_i > 32
            when :ipv6
              return false if prefixlen.to_i > 128
            else
              return false
            end
            return {:ip => addr, :prefixlen => prefixlen} 
          else                    # just the address
            addr = str
            proto = self.valid_address?(addr)
            case proto
            when :ipv4
              return {:ip => addr, :prefixlen => "32"}
            when :ipv6
              return {:ip => addr, :prefixlen => "128"}
            else
              return false
            end
          end
        end

        def self.valid_address?(str)
          addr = str.strip
          if addr =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ # IPv4
            [$1, $2, $3, $4].each do |byte|
              return false if byte.to_i > 255
            end
            return :ipv4
          elsif addr =~ /^[\da-f:]+$/i                              # IPv6
            return :ipv6 if addr == '::'
            return false if addr =~ /::.*::/
            return false if addr =~ /:::/
            return false unless addr =~ /[\da-f]/i
            words = addr.split(':')
            return false if words.length < 8 and not addr =~ /::/
            words.each do |word|
              return false if word.to_i(16) > 0xffff
            end
            return :ipv6
          else
            return false
          end
        end

        # turn the @ip Array (made up of 
        # OnBoard::Network::Interface::IP objects) into an Hash of Strings, 
        # just like what it would be received from an HTML form.
        #
        # Just a wrapper around OnBoard::Network::Interface#assign_static_ip, 
        # which was designed to get form data, not saved marshaled objects.
        #
        # Also, we consider the JSON client,
        # which is "ReSTfully happy" to send ["1.1.1.1/1", "2.2.2.2/2"]
        # rather than {"0": "1.1.1.1/1", "1": "2.2.2.2/2"}.
        def self.ary_to_StringHash(ipary)
          h = {}
          ipary.each_with_index do |ip_obj, ip_idx|
            ip_fulladdr_str = case ip_obj
            when String
              ip_obj
            else
              ip_obj.addr.to_s + '/' + ip_obj.prefixlen.to_s
            end
            h[ip_idx.to_s] = ip_fulladdr_str
          end
          return h
        end

      end
    end
  end
end


