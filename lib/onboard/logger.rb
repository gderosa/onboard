require 'fileutils'
require 'logger'

require 'onboard/constants'

class OnBoard

  LOGDIR = File.join RWDIR, '/var/log'
  LOGFILE_BASENAME    = 'onboard.log'
  LOGFILE_PATH        = File.join LOGDIR, LOGFILE_BASENAME
  LOGFILE             = LOGFILE_PATH

  LOGGER = Logger.new(STDOUT)

  LOGGER.formatter = proc do |severity, datetime, progname, msg|
    "#{datetime} #{severity}: #{msg}\n"
  end

  # Client code will optionally use the default logfile w/ methods below:

  class << self

    def use_logfile(logfile=LOGFILE)
      FileUtils.mkdir_p File.dirname LOGDIR
      LOGGER.reopen logfile
    end

    def use_default_logfile
      use_logfile(LOGFILE)
    end

    def log_to_stdout
      LOGGER.reopen STDOUT
    end

  end

end
