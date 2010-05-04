class OnBoard
  module Network
    module Routing
      autoload :Route,  'onboard/network/routing/route'
      autoload :Table,  'onboard/network/routing/table'
      autoload :Rule,   'onboard/network/routing/rule'

      CONFDIR = File.join OnBoard::CONFDIR, 'network/routing'
    end
  end
end


