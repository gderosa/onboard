require 'sinatra/base'

module Sinatra
  module Templates

    unless method_defined? :erubis
      warn 'OnBoard: Sinatra::Templates#erubis has been removed, aliasing to erb (which will use erubis automatically, if present)'
      alias erubis erb
    end

  end
end


