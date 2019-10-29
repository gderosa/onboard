class OnBoard
  class Controller < ::Sinatra::Base

    case environment
    when :development
      OnBoard::LOGGER.level = Logger::DEBUG
    when :production
      OnBoard::LOGGER.level = Logger::INFO
    end

  end
end
