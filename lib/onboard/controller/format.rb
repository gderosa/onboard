class OnBoard
  class Controller < ::Sinatra::Base

    @@formats = %w{html json yaml} # order matters
    @@formats << 'rb' if development?

  end
end

