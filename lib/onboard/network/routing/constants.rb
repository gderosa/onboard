class OnBoard
  module Network
    module Routing

      CONFDIR = File.join OnBoard::CONFDIR, 'network/routing'

      class RulesExist < ::RuntimeError; end

    end
  end
end


