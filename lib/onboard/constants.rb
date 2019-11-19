class OnBoard
  LONGNAME          ||= 'OnBoard'
  VERSION           = '2019.14'
  FILESDIR            ||= File.join ENV['HOME'], 'files' # mass storage...
  ROOTDIR = File.join(File.dirname(__FILE__), '../..')
  RWDIR = (
    ENV['ONBOARD_RWDIR'] or
    ENV['ONBOARD_DATADIR'] or
    File.join(ENV['HOME'], '.onboard')
  )
  DATADIR = RWDIR
  CONFDIR = File.join RWDIR, '/etc/config'
  VARRUN              ||= '/var/run/onboard'
  VARLIB              ||= File.join RWDIR, 'var/lib'
  # sometimes files are uploaded elsewhere, as best suitable
  DEFAULT_UPLOAD_DIR  = File.join RWDIR, '/var/uploads'
end
