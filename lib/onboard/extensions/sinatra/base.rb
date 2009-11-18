module Sinatra
  class Base
    def routed?(path, verb="GET") 
      self.class.routes[verb].each do |pattern, keys, conditions, block|
        if pattern.match path and not pattern.match '/pretty_much.anything'
          return true
        end
      end
      return false
    end
  end
end
