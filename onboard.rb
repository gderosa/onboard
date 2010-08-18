# encoding: utf-8

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib'

require 'rubygems'
require 'find'
require 'json'
require 'yaml'
require 'logger'
require 'pp' 
require 'etc'

require 'onboard/extensions/object'
require 'onboard/menu/node'

require 'onboard/platform/debian'

begin
  require 'onboard/constants/custom'
rescue LoadError
end

if Process.uid == 0
  fail 'OnBoard should not be run as root: use an user who can sudo with no-password instead!'
end

class OnBoard
  LONGNAME          ||= 'OnBoard'
  VERSION           = '2010.08'

  PLATFORM          = Platform::Debian # TODO? make it configurable? get rid of Platform?

  ROOTDIR           = File.dirname File.expand_path(__FILE__)
  DATADIR = RWDIR = (
      ENV['ONBOARD_RWDIR'] or 
      ENV['ONBOARD_DATADIR'] or 
      File.join(ENV['HOME'], '.onboard')
  )
  CONFDIR           = File.join RWDIR, '/etc/config'
  LOGDIR            = File.join RWDIR, '/var/log'
  LOGFILE_BASENAME  = 'onboard.log'
  LOGFILE_PATH      = File.join LOGDIR, LOGFILE_BASENAME
 
  FileUtils.mkdir_p LOGDIR unless Dir.exists? LOGDIR
  LOGGER            = Logger.new(LOGDIR + '/' + 'onboard.log')
  
  LOGGER.formatter = proc { |severity, datetime, progname, msg|
    "#{datetime} #{severity}: #{msg}\n"
  }

  LOGGER.level = Logger::INFO
  LOGGER.level = Logger::DEBUG if 
      $0 == __FILE__ and not
      ENV['ONBOARD_ENVIRONMENT'] =~ /production/i
      # this is required because there is no Sinatra environment until
      # controller.rb is loaded (where OnBoard::Controller inherits 
      # from Sinatra::Base)

  MENU_ROOT = Menu::MenuNode.new('ROOT', {
    :href => '/',
    :name => 'Home',
    :desc => 'Home page',
    :n    => 0
  })

  def self.find_n_load(dir)
    # sort to resamble /etc/rc*.d/* or run-parts behavior
    Find.find(dir).sort.each do |file|
      if file =~ /\.rb$/
        print "loading: #{file}... "
        STDOUT.flush
        if load file
          print "OK\n"
          STDOUT.flush
        end
      end
    end
  end

  def self.web?
    return true unless ARGV.include? '--no-web'
    return false
  end

  def self.prepare
    # menu
    if web?
      # modular menu
      find_n_load ROOTDIR + '/etc/menu/'
    end

    # modules
    Dir.foreach(ROOTDIR + '/modules') do |dir|
      dir_fullpath = ROOTDIR + '/modules/' + dir
      if File.directory? dir_fullpath and not dir =~ /^\./
        file = dir_fullpath + '/load.rb'
        if File.readable? file
          load dir_fullpath + '/load.rb'
        else
          STDERR.puts "Warning: Couldn't load modules/#{dir}/load.rb: Skipped!"
        end
      end 
    end

    # restore scripts, sorted like /etc/rc?.d/ SysVInit/Unix/Linux scripts
    if ARGV.include? '--restore' 
      restore_scripts = 
          Dir.glob(ROOTDIR + '/etc/restore/[0-9][0-9]*.rb')           +
          Dir.glob(ROOTDIR + '/modules/*/etc/restore/[0-9][0-9]*.rb') 
      restore_scripts.sort!{|x,y| File.basename(x) <=> File.basename(y)}
      restore_scripts.each do |script|
        print "loading: #{script}... "
        STDOUT.flush
        begin
          load script and puts "OK"
        rescue
          exception = $!

          puts exception.inspect

          LOGGER.error "loading #{script}: #{exception.inspect}"
          backtrace_str = "Exception backtrace follows:"
          exception.backtrace.each{|line| backtrace_str << "\n" << line} 
          LOGGER.error backtrace_str
        end
      end
    end

  end

  def self.save!
    LOGGER.info 'Saving configuration...'
    find_n_load ROOTDIR + '/etc/save/'

    # modules
    Dir.glob(ROOTDIR + '/modules/*/etc/save/*.rb').each do |script| 
      print "loading: #{script}... " and STDOUT.flush
      load script and puts ' OK'
    end
  end

end

OnBoard.prepare

if OnBoard.web?
  require OnBoard::ROOTDIR + '/controller.rb'
  if $0 == __FILE__
    OnBoard::Controller.run!
  end
end



