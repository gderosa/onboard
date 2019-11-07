# TODO: move all constants here and DRY with root onboard.rb
# At the moment this is mostly useful from standalone scripts like openvpn --up etc.
class OnBoard
  FILESDIR            ||= File.join ENV['HOME'], 'files' # mass storage...

  ROOTDIR = File.join(File.dirname(__FILE__), '../..') unless defined? ROOTDIR
  RWDIR = (
    ENV['ONBOARD_RWDIR'] or
    ENV['ONBOARD_DATADIR'] or
    File.join(ENV['HOME'], '.onboard')
  ) unless defined? RWDIR
  DATADIR = RWDIR unless defined? DATADIR
  CONFDIR = File.join RWDIR, '/etc/config' unless defined? CONFDIR
end



