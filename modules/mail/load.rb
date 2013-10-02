class OnBoard
  module Service
    module Mail
      ROOTDIR = File.dirname(__FILE__)
      CONFDIR = File.join ::OnBoard::CONFDIR, '/services/mail'
      FileUtils.mkdir_p CONFDIR unless Dir.exists? CONFDIR
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      if OnBoard.web?
        OnBoard.find_n_load ROOTDIR + '/etc/menu'
        OnBoard.find_n_load ROOTDIR + '/controller'
      end
    end
  end
end

