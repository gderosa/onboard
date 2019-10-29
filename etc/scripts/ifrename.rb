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
  opts.on("-r", "--reverse", "sort in reverse order") do |rev|
    options[:reverse] = rev
  end
#  opts.on("-n", "--udev-kernel-name NAME", String, "interface name (only the new name will be printed in this case: for use in PROGRAM=/this/script in /etc/udev/rules.d/*-persistent-net.rules), instead of ifrename /etc/iftab") do |name|
#    options[:udev_kernel_name] = name
#  end
end.parse!

start_from        = options[:start_from] || 0
format            = options[:format] || "ETH%02d" # as in ZeroShell ;-PPPP
type              = options[:type] || 'ether'
reverse           = options[:reverse]
#udev_kernel_name  = options[:udev_kernel_name]

ordered_interfaces = OnBoard::Network::Interface.getAll.select do |iface|
  type == 'any' or type == iface.type
end.sort do |x, y|
  reverse ?
    (y.mac <=> x.mac)
  :
    (x.mac <=> y.mac)
end

new_names     = []
iftab_lines   = []
#udev_new_name = nil

ordered_interfaces.each_with_index do |iface, idx|
  new_name  = sprintf("#{format}", (idx + start_from))
  old_name  = iface.name
  mac       = iface.mac.to_s
  new_names << new_name
  iftab_lines <<
      "#{new_name} mac #{mac} # formerly #{old_name} \n"
#  if udev_kernel_name and udev_kernel_name == old_name
#    udev_new_name = new_name
#  end
end

#if udev_new_name                # use udev
#  puts udev_new_name
#elsif udev_kernel_name
  #STDERR.puts "device #{udev_kernel_name} not found!"
  #exit 127
#  puts "#{udev_kernel_name}_ren"
#else                            # use ifrename
#  iftab_lines.each {|l| puts l}
#end

iftab_lines.each {|l| puts l}




