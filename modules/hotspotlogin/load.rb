require 'fileutils'

class OnBoard
  module Service
    class HotSpotLogin
      ROOTDIR = File.dirname(__FILE__)
      CONFDIR = File.join CONFDIR, '/services/hotspotlogin'
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      if OnBoard.web?
        OnBoard.find_n_load ROOTDIR + '/etc/menu'
        OnBoard.find_n_load ROOTDIR + '/controller'
      end
    end
  end
end


