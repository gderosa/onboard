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

    private

    # Overwrite Sinatra::Base private method!!! (is this robust?)
    #
    # Allow settings.public to be an Array (or Enumerable...) 
    # for multiple-path static file lookup.
    alias static_orig! static!
    def static!
      return if settings.public.nil?      
      if settings.public.respond_to? :each
        settings.public.each do |dir|
          public_dir = File.expand_path(dir)
          
          path = File.expand_path(public_dir + unescape(request.path_info))
          next if path[0, public_dir.length] != public_dir
          next unless File.file?(path)
          
          env['sinatra.static_file'] = path
          send_file path, :disposition => nil

          break
        end
      else
        static_orig!
      end
    end

  end
end
