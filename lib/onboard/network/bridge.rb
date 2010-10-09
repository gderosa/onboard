require 'onboard/system/command'

class OnBoard::Network::Bridge < OnBoard::Network::Interface

  class << self

    include OnBoard::System

    def brctl(h)
      msg = {}
      unless h.respond_to? :[]
        {
            :ok => false,
            :err => 'No valid data provided'
        }
      end
      ['addif', 'delif'].each do |command|
        h[command].each_pair do |bridgename, ifh|
          ifh.each_pair do |ifname, value| 
            Command.run "brctl #{command} #{bridgename} #{ifname}", :sudo if 
                value and not [0, "0", "no", "false", "off"].include? value
          end
        end if h.respond_to? :[] and h[command].respond_to? :each_pair
      end  
      if h.respond_to? :[] and h['addbr']
        substitution = h['addbr'].sub! /\s.*$/, '' 
            # truncate anything after a space (if any), to avoid command 
            # injection
        if substitution 
          msg[:warn] = 'Bridge name has been truncated'
        end
        unless h['addbr'] =~ /\S/
          return {:ok => false, :err => 'No valid bridge name!'}
        end
        msg.merge! Command.run "brctl addbr #{h['addbr']}", :sudo 
        if msg[:ok]
          msg.merge! Command.run "ip link set #{h['addbr']} up", :sudo
        end
        return msg
      end
      if h.respond_to? :[] and h['delbr']
        h['delbr'].sub! /\s.*$/, '' # truncate anything after a space (if any),
            # to avoid command injection
        Command.run "ip link set #{h['delbr']} down", :sudo
        Command.run "brctl delbr #{h['delbr']}", :sudo
      end
    end

  end

  def initialize(parentClassObjTemplate)
    parentClassObjTemplate.instance_variables.each do |ivar|
      instance_variable_set(
        ivar,
        parentClassObjTemplate.instance_variable_get(ivar)
      )
    end
    @type = 'bridge' unless @type == 'bridge' # ;-)
    @bridgedir = "/sys/class/net/#@name/bridge"
    @bridgeifdir = "/sys/class/net/#@name/brif"
    @members = members
  end

  # *current* mmebers
  def members
    if Dir.exists? @bridgeifdir
      @members = 
          Dir.entries(@bridgeifdir).reject{|x| x =~ /^\./} # remove '.' and '..'
    else
      @members = []
    end
    return @members
  end

  # useful for restore
  def members_saved
    @members
  end

  # Override the @ip accessor, adding the IP objects of the bridged interfaces
  def ip
    ary = []
    ary += @ip if @ip
    member_netifs.each do |member_netif|
      ary += member_netif.ip if member_netif.ip
    end
    return ary
  end

  def ip_addr_del(ipobj)
    if has_ip? ipobj
      return super(ipobj)
    else
      member_netifs.each do |member_netif|
        if member_netif.has_ip? ipobj
          return member_netif.ip_addr_del(ipobj)
        end
      end
    end
  end

  def data
    super.update('members' => @members)
  end
  alias to_h data

  private

  def member_netifs
    OnBoard::Network::Interface.all_layer2.select do |netif| 
      netif.bridged_to == @name
    end
  end

end

