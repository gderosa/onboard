# encoding: utf-8

require 'rubygems'
require 'set'
require 'thin' 
require 'sinatra/base'
require 'sinatra/r18n'
require 'locale'
require 'erubis'
require 'find'
require 'json'
require 'yaml'
require 'logger'
require 'rack/utils'

require 'onboard/extensions/object'
require 'onboard/extensions/object/deep'
require 'onboard/extensions/sinatra/base'
require 'onboard/menu/node'
require 'onboard/passwd'

require 'onboard/controller/auth'
require 'onboard/controller/locale'

class OnBoard
  class Controller < ::Sinatra::Base

    class ArgumentError < ArgumentError; end # who uses this?

    # Extensions must be explicitly registered in modular style apps.
    register ::Sinatra::R18n

    # Several options are not enabled by default if you inherit from 
    # Sinatra::Base .
    enable :method_override, :static, :show_exceptions
    
    set :root, OnBoard::ROOTDIR

    # Sinatra::Base#static! has been overwritten to allow multiple path
    set :public, 
        Dir.glob(OnBoard::ROOTDIR + '/public')            +
        Dir.glob(OnBoard::ROOTDIR + '/modules/*/public')      

    set :views, OnBoard::ROOTDIR + '/views'

    case environment
    when :development
      Thread.abort_on_exception = true
      OnBoard::LOGGER.level = Logger::DEBUG
    when :production
      Thread.abort_on_exception = false
      OnBoard::LOGGER.level = Logger::INFO
    end

    # TODO: do not hardcode, make it themable :-)
    IconDir = '/icons/gnome/gnome-icon-theme-2.18.0'
    IconSize = '16x16'
    
    @@formats = %w{html json yaml} # order matters
    @@formats << 'rb' if development?

    not_found do
      ## Commented out since it breaks any explicit call to not_found
      ## TODO: find something better
      #
      #if routed? request.path_info, :any 
      #  status(405) # HTTP Method Not Allowed
      #  headers "Allow" => allowed_methods(request.path_info).join(', ')
      #  format(:path=>'405', :format=>'html')
      #else
        status(404)
        format(:path=>'404', :format=>'html') 
      #end
    end

    # modular controller
    OnBoard.find_n_load OnBoard::ROOTDIR + '/controller/'

  end

end
