require 'sinatra/r18n'

class OnBoard
  class Controller < ::Sinatra::Base

    # Extensions must be explicitly registered in modular style apps.
    register ::Sinatra::R18n

  end
end    
