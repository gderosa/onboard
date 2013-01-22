require 'fileutils'

class OnBoard
  module Virtualization
    module QEMU

      ROOTDIR   = File.dirname(__FILE__)
      CONFDIR   = File.join OnBoard::CONFDIR, 'virtualization/qemu'
      
      FileUtils.mkdir_p CONFDIR
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      if OnBoard.web?
        OnBoard.find_n_load ROOTDIR + '/etc/menu'
        OnBoard.find_n_load ROOTDIR + '/controller'
      end

    end
  end
  V12n = Virtualization 
end

