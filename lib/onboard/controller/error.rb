require 'sinatra/base'

class OnBoard
  class Controller < Sinatra::Base

    class ArgumentError < ArgumentError; end # who uses this?

    class << self
      # Different from standard Sinatra error handler:
      # * allow multiple blocks for the same exception (called subsequently)
      # * does not require disabling :show_exceptions (which is still useful
      #   for unhandled exceptions).
      #
      # Each handler returns a Hash, like {:status => 409. :msg => {...}}
      # or nil if the error cannot be handled. msg Hash will be used
      # by message_partial .
      def on_error(exception, &blk)
        @@error_handlers ||= {}
        @@error_handlers[exception] ||= []
        @@error_handlers[exception] << blk
      end
    end
  end
end

