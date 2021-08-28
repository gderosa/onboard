require 'json'

require 'onboard/system/command'
require 'onboard/network/interface'

class OnBoard::Network::Bridge < OnBoard::Network::Interface

  class << self

    include OnBoard::System

    def get_all
      all = OnBoard::Network::Interface.get_all.select{|x| x.type == 'bridge'}
      all.each do |br|
        br.stp = br.stp?
      end
      return all
    end

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
      if h.respond_to? :[] and h['stp']
        h['stp'].each_pair do |brname, onoff|
          brname = brname.strip
          if [0, false, 'no'].include? onoff
            onoff = 'on'
          elsif [1, true, 'yes'].include? onoff
            onoff = 'on'
          end
          Command.run "brctl stp #{brname} #{onoff}", :sudo
        end
      end
    end

  end

  attr_accessor :stp

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

  # Override the @vlan_info accessor, adding VLAN IDs of the bridged interfaces
  def vlan_info
    vlan_info_new = @vlan_info.clone
    member_netifs.each do |member_netif|
      if member_netif.vlan_info
        vlan_info_new[:ids] += member_netif.vlan_info[:ids]
      end
    end
    vlan_info_new[:ids].uniq!
    vlan_info_new[:ids].sort!
    return vlan_info_new
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

  def stp?
    JSON.parse(`ip -j -d link show dev #{@name}`).first['linkinfo']['info_data']['stp_state'] > 0
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

