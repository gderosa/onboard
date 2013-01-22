require 'fileutils'

require 'onboard/network/dnsmasq'

version_file = File.join OnBoard::CONFDIR, 'VERSION'

begin
  File.open version_file, 'w' do |f|
    f.write OnBoard::VERSION
  end
rescue
  FileUtils.mkdir_p OnBoard::CONFDIR
  retry
end



