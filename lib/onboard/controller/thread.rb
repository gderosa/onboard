class OnBoard
  class Controller < ::Sinatra::Base

    case environment
    when :development
      Thread.abort_on_exception = true
    when :production
      Thread.abort_on_exception = false
    end

  end
end
