class OnBoard
  module Service
    module Mail
      ROOTDIR ||= File.join __FILE__, '../../../..'
      CONFDIR ||= File.join OnBoard::CONFDIR, 'services/mail'
    end
  end
end
