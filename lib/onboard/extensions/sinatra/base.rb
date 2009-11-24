module Sinatra
  class Base
    def routed?(path, verb="GET")
      if verb == :any
        %w{GET POST PUT DELETE}.each do |verb_|
          return true if routed? path, verb_
        end
        return false
      else 
        self.class.routes[verb].each do |pattern, keys, conditions, block|
          if pattern.match path and not pattern.match '/pretty_much.anything'
            return true
          end
        end
        return false
      end
    end
    def allowed_methods(path)
      methods = self.class.routes.keys
      retval = methods.dup
      methods.each do |verb|
        retval.delete verb unless routed? path, verb
      end
      return retval
    end
  end
end
