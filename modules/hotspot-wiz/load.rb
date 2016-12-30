class OnBoard
  module Network
    module AccessControl
      class HSWiz
        ROOTDIR = File.dirname(__FILE__)
        CONFDIR = File.join OnBoard::CONFDIR, '/network/access-control/hotspot-wiz'
        $LOAD_PATH.unshift  ROOTDIR + '/lib'
        if OnBoard.web?
          OnBoard.find_n_load ROOTDIR + '/etc/menu'
          OnBoard.find_n_load ROOTDIR + '/controller'
        end
      end
    end
  end
end
