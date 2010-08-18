require 'onboard/network/dnsmasq'

version_file = File.join OnBoard::CONFDIR, 'VERSION'

File.open version_file, 'w' do |f|
  f.write OnBoard::VERSION
end



