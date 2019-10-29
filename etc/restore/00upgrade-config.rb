require 'onboard/extensions/array'
require 'onboard/system/command'

# something like [2010, 8]
current_version = OnBoard::VERSION.split('.').map{|s| s.to_i}

begin
  saved_configuration_version_str = File.read File.join OnBoard::CONFDIR, 'VERSION'
  saved_configuration_version = saved_configuration_version_str.split('.').map{|s| s.to_i}
rescue Errno::ENOENT
  saved_configuration_version = [0, 0, 0]
end

if
    Dir.exists? OnBoard::CONFDIR              and # No config? Do not upgrade ;)
    saved_configuration_version <   [2010, 8] and
    current_version             >=  [2010, 8]

  print "\nNOTE: Upgrading configuration to version #{OnBoard::VERSION} ... "

  cmd = "#{OnBoard::ROOTDIR}/etc/scripts/migrate-config.sh"
  OnBoard::System::Command.run cmd

  load File.join OnBoard::ROOTDIR, '/etc/save/version.rb'
end




