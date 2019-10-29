require 'ipaddr'

class IPAddr

  class << self

    # Due to probability, about n attempts are required on average
    # to get an address in 192.168.0.0/16 from random_rfc1918()
    #
    # n = ( p_10 + p_172 + p_192 ) / p_192 = 273
    # p_10 = 2**24  # 10.0.0.0/8 addresses
    # p_172 = 2**20 # 172.16.0.0/12 adresses
    # p_192 = 2**16 # 192.168.0.0/16 addresses
    def test_until_192_168
      net_192_168 = IPAddr.new '192.168.0.0/16'
      ip = IPAddr.new '127.0.0.1'
      attempts = 0
      until net_192_168.include?(ip)
        ip = random_rfc1918
        attempts += 1
        puts "#{attempts}: #{ip}"
      end
    end

    def random_rfc1918
      random_multiple('192.168.0.0/16', '172.16.0.0/12', '10.0.0.0/8')
    end

    # Returns an IPAddr within one of the nets. It's probability-aware,
    # meaning that the likelihood of getting an address in one net or
    # another is proportional to its "width".
    #
    #   IPAddr.random_multiple('192.168.0.0/16', '172.16.0.0/12', '10.0.0.0/8')
    def random_multiple(*nets)
      ip_nets = []
      nets.each do |net|
        if net.is_a? IPAddr
          ip_net = net
        else
          ip_net = IPAddr.new(net)
        end
        ip_nets << ip_net
      end
      p = []
      partition = []
      p_tot = 0
      ip_nets.each do |ip_net|
        bits = ip_net.addresslen - ip_net.prefixlen
        pn = 2**bits
        p << pn
        p_tot += pn
        partition << p_tot
      end
      n = rand(p_tot)
      selected_set_i = 0
      offset = 0
      partition.each_with_index do |upper_end, i|
        if i == 0 and n <= upper_end
          offset = n
          break
        elsif n > partition[i-1] and n < partition[i]
          selected_set_i = i
          offset = n - partition[i-1]
          break
        end
      end
      return ip_nets[selected_set_i] + offset
    end

    def random(first_or_net, last=nil)
      if first_or_net.kind_of? String
        first_or_net = IPAddr.new first_or_net
      end
      if last.kind_of? String
        last = IPAddr.new last
      end
      af = first_or_net.family # Socket::AF_INET or Socket::AF_INET6
      if last
        first = first_or_net
      else
        net   = first_or_net
        first = net.to_range.first
        last  = net.to_range.last
      end
      IPAddr.new(
        first.to_i + rand(last.to_i - first.to_i),
        af
      )
    end
  end

  def +(other)
    IPAddr.new(self.to_i + other.to_i, self.family)
  end

  def -(other)
    self.+(-(other.to_i))
  end

  def netmask
    IPAddr.new @mask_addr, @family
  end

  def addresslen
    case @family
    when Socket::AF_INET
      32
    when Socket::AF_INET6
      128
    end
  end

  def prefixlen
    # a crude way to get prefix length from netmask: convert to a binary
    # string, remove all the '0' and count the remaining '1' ;-P

    @mask_addr.to_s(2).gsub('0','').length
  end

  def to_cidr
    "#{self.to_s}/#{self.prefixlen}"
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
  def rfc1918?
    case self
    when IPAddr.new('10.0.0.0/8')
      true
    when IPAddr.new('172.16.0.0/12')
      true
    when IPAddr.new('192.168.0.0/16')
      true
    else
      false
    end
  end
  def private_ip?
    rfc1918? or link_local? or loopback?
  end
  def public_ip?
    not private_ip?
  end

end
