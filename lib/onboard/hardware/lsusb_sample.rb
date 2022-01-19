
$LOAD_PATH.unshift File.join File.dirname(__FILE__), '../..'

require 'pp'

require 'onboard/hardware/lsusb'

include OnBoard::Hardware

LSUSB.all.each do |dev|
  pp dev
end

puts

pp LSUSB.all

puts

pp LSUSB.all.to_a

