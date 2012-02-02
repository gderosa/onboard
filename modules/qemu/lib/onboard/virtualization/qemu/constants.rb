class OnBoard
  module Virtualization
    module QEMU

      ROOTDIR   = File.dirname(__FILE__)
      CONFDIR   = File.join OnBoard::CONFDIR, 'virtualization/qemu'
      
      # TODO: move elsewhere or make it more flexible
      FILESDIR  = '/home/onboard/files' 

    end
  end
end

