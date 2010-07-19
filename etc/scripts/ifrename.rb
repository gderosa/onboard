#!/usr/bin/env ruby

# Rename network interfaces, ordering them by MAC address. For example:
#
#   ifrename.rb --type ether --format "LAN%02d" --start-from 1 >> /path/to/iftab
#
# renames ethernets as: LAN01, LAN02, ... LAN99
#
#   ifrename.rb --type wi-fi --format "wl%d" >> /path/to/iftab
#
# will rename wireless devices as: wl0, wl1 ..
#
# --type may be wi-fi, ether or loopback
#
# --format recalls printf syntax
#
# You have to execute /sbin/ifrename /path/to/iftab (the system utility) 
# to get the interfaces actually renamed. If /path/to/iftab is /etc/iftab,
# reboot the system and the OS will take care of this (which is recommended,
# because running /sbin/ifrename on a running system could led to a "device busy"
# error).
#
#


$LOAD_PATH.unshift(
  File.expand_path (
    File.join File.dirname(__FILE__), '../../lib'
  )
)

require 'optparse'

require 'onboard/network/interface'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-t", "--type TYPE", String, "ether, wi-fi or loopback") do |type|
    options[:type] = type
  end
  opts.on("-f", "--format FORMAT", String, "printf-like format string") do |format|
    options[:format] = format
  end
  opts.on("-s", "--start-from START_FROM", Integer, "number to start from") do |start_from|
    options[:start_from] = start_from
  end
end.parse!

n       = options[:start_from] || 0
format  = options[:format] || "ETH%02d" # as in ZeroShell ;-PPPP

OnBoard::Network::Interface.getAll.select do |iface| 
  options[:type] == 'any' or options[:type] == iface.type
end.sort do |x, y| 
  x.mac <=> y.mac
end.each do |iface|
  printf "#{format} mac #{iface.mac} # formerly #{iface.name} \n", n
  n += 1
end



