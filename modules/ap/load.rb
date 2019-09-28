class OnBoard
  module Network
    module AP
      ROOTDIR = File.dirname(__FILE__)
      CONFDIR = File.join OnBoard::CONFDIR, '/network/ap'
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      if OnBoard.web?
        OnBoard.find_n_load ROOTDIR + '/etc/menu'
        OnBoard.find_n_load ROOTDIR + '/controller'
      end
    end
  end
end


