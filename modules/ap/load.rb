require 'fileutils'

class OnBoard
  module Network
    module AP
      ROOTDIR = File.dirname(__FILE__)
      CONFDIR = File.join OnBoard::CONFDIR, '/network/ap'
      LOGDIR  = File.join OnBoard::LOGDIR, '/network/ap'
      VARRUN  = File.join OnBoard::VARRUN, '/network/ap'
      FileUtils::mkdir_p CONFDIR + '/new'
      FileUtils::mkdir_p LOGDIR
      FileUtils::mkdir_p VARRUN
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      if OnBoard.web?
        OnBoard.find_n_load ROOTDIR + '/etc/menu'
        OnBoard.find_n_load ROOTDIR + '/controller'
      end
    end
  end
end


