require 'sinatra/base'

require 'onboard/extensions/sinatra/base'
require 'onboard/extensions/sinatra/templates'

class OnBoard
  class Controller < ::Sinatra::Base

    @@formats = %w{html json yaml} # order matters
    @@formats << 'rb' if development?

  end
end

