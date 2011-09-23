# encoding: utf-8

class OnBoard
  class Controller < ::Sinatra::Base

    @@public_access = Set.new

    def self.public_access!(path)
      @@public_access ||= Set.new
      @@public_access << path
    end
    def self.protected_access!(path) # which is default, useful to re-protect...
      @@public_access.delete path
    end
    def self.public_access?(path)
      class_variable_defined? :@@public_access and @@public_access.any? {|m| m === path}      end

    before do
      protected! unless self.class.public_access? request.path_info

      if request.path_info =~ %r{^/pub(/.*)?$}
        if mobile?
          @layout = 'pub/layout.mobi.html'
        else
          @layout = 'pub/layout.html'
        end
      end
    end    

    # All URLs under /pub/ are publicly accessible! 
    public_access! %r{^/pub(/.*)?$} 
  
    # 
    public_access! %r{^/__sinatra__(/.*)?$} 

  end

end
