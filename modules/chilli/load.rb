class OnBoard
  module Network
    module AccessControl
      class Chilli
        ROOTDIR = File.dirname(__FILE__)
        CONFDIR = File.join ROOTDIR, '/etc/config'
        $LOAD_PATH.unshift  ROOTDIR + '/lib'
        OnBoard.find_n_load ROOTDIR + '/etc/menu'
        OnBoard.find_n_load ROOTDIR + '/controller'
      end
    end
  end

  CHILLI_CLASS = Network::AccessControl::Chilli # a shortcut
end


