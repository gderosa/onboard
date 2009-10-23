require 'ipaddr'

class IPAddr

  def netmask
    IPAddr.new @mask_addr, @family
  end

  def prefixlen
    # a crude way to get prefix length from netmask: convert to a binary 
    # string, remove all the '0' and count the remaining '1' ;-P

    @mask_addr.to_s(2).gsub('0','').length
  end

  # for JSON export etc.
  def data
    {
      'addr'      => to_s,
      'prefixlen' => prefixlen,
      'af'        => (
          case @family
          when Socket::AF_INET
            'inet'
          when Socket::AF_INET6
            'inet6'
          end
      ) 
    }
  end

  def loopback?
    case @family
    when Socket::AF_INET
      return IPAddr.new("127.0.0.1/8").include? self
    when Socket::AF_INET6
      return IPAddr.new("::1/128").include? self
    else 
      raise RuntimeError, "IPAddr object @family is neither Socket::AF_INET nor Socket::AF_INET6 so I can't say wheter it's a loopback address or not"
    end
  end
  def multicast?
    case @family
    when Socket::AF_INET
      return IPAddr.new("224.0.0.0/4").include? self
    when Socket::AF_INET6
      return IPAddr.new("ff00::/8").include? self
    else 
      raise RuntimeError, "IPAddr object @family is neither Socket::AF_INET nor Socket::AF_INET6 so I can't say wheter it's a multicast or not"
    end
  end
  def link_local?
    case @family
    when Socket::AF_INET
      return IPAddr.new("169.254.0.0/16").include? self
    when Socket::AF_INET6
      return IPAddr.new("fe80::/10").include? self
    else
      raise RuntimeError, "IPAddr object @family is neither Socket::AF_INET nor Socket::AF_INET6 so I can't say wheter it's a link-local or not"
    end
  end

end
