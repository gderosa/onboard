require 'fileutils'

class OnBoard
  module V12n 
    module QEMU
      ROOTDIR = File.dirname(__FILE__)
      CONFDIR = File.join OnBoard::CONFDIR, 'v12n/qemu'
      FileUtils.mkdir_p CONFDIR
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      if OnBoard.web?
        OnBoard.find_n_load ROOTDIR + '/etc/menu'
        OnBoard.find_n_load ROOTDIR + '/controller'
      end
    end
  end
  Virtualization = V12n 
end

