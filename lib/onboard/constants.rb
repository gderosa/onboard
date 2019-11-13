require 'logger'

# TODO: move all constants here and DRY with root onboard.rb
# At the moment this is mostly useful from standalone scripts like openvpn --up etc.
class OnBoard
  LONGNAME          ||= 'OnBoard'
  VERSION           = '2019.13.1'
  FILESDIR            ||= File.join ENV['HOME'], 'files' # mass storage...
  ROOTDIR = File.join(File.dirname(__FILE__), '../..')
  RWDIR = (
    ENV['ONBOARD_RWDIR'] or
    ENV['ONBOARD_DATADIR'] or
    File.join(ENV['HOME'], '.onboard')
  )
  DATADIR = RWDIR
  CONFDIR = File.join RWDIR, '/etc/config'
  # sometimes files are uploaded elsewhere, as best suitable
  DEFAULT_UPLOAD_DIR  = File.join RWDIR, '/var/uploads'
  LOGDIR = File.join RWDIR, '/var/log'
  LOGFILE_BASENAME    = 'onboard.log'
  LOGFILE_PATH        = File.join LOGDIR, LOGFILE_BASENAME
  VARRUN              ||= '/var/run/onboard'
  VARLIB              ||= File.join RWDIR, 'var/lib'

  LOGGER = Logger.new(LOGFILE_PATH)
end



