require 'fileutils'

class OnBoard
  module Service
    class HotSpotLogin
      ROOTDIR = File.dirname(__FILE__)
      CONFDIR = File.join ROOTDIR, '/etc/config'
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      OnBoard.find_n_load ROOTDIR + '/etc/menu'
      OnBoard.find_n_load ROOTDIR + '/controller'

      unless File.exists? CONFFILE
        FileUtils.cp DEFAULT_CONFFILE, CONFFILE
      end
    end
  end
end


