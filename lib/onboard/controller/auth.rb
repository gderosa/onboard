# encoding: utf-8

require 'sinatra/base'

class OnBoard
  class Controller < ::Sinatra::Base

    @@public_access = Set.new

    class << @@public_access
      attr_writer :actually_used
      def actually_used?
        @actually_used ||= false
      end
      def actually_used
        @actually_used ||= false
      end
    end
    def self.public_access
      @@public_access
    end
    def self.public_pages?
      @@public_access.actually_used?
    end
    def self.public_pages=(value)
      @@public_access.actually_used = value
    end
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
      protected! unless self.class.public_access? request.path_info or ENV['APP_ENV'] == 'test'

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

  class << self
    def public_pages=(bool)
      Controller.public_pages = bool
    end
    def public_pages?
      Controller.public_pages?
    end
    def use_public_pages!
      Controller.public_pages = true
    end
  end

end
