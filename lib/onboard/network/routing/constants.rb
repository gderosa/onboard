class OnBoard
  module Network
    module Routing

      CONFDIR = OnBoard.const_defined?(:CONFDIR) ?
        File.join(OnBoard::CONFDIR, 'network/routing') :
        nil

      class RulesExist < ::RuntimeError; end

    end
  end
end


