# encoding: utf-8

require 'rubygems'
require 'thin'
require 'sinatra/base'
require 'tilt/erb'

require 'rack'
require 'rack/contrib'

require 'onboard/extensions/sinatra/base'

require 'onboard/controller/auth'
require 'onboard/controller/error'
require 'onboard/controller/format'
require 'onboard/controller/gui'
require 'onboard/controller/locale'
require 'onboard/controller/logger'
require 'onboard/controller/thread'

class OnBoard
  class Controller < ::Sinatra::Base

    attr_accessor :msg
        # so you don't need to pass it between routes, views, helpers ...

    before do
      @msg = {}
    end

    # Several options are not enabled by default if you inherit from
    # Sinatra::Base .
    enable :method_override, :static, :show_exceptions

    if test?  # https://stackoverflow.com/a/10917840
      set :raise_errors, true
      set :dump_errors, false
      set :show_exceptions, false
    end

    set :root, OnBoard::ROOTDIR

    # Sinatra::Base#static! has been overwritten to allow multiple path
    set :public_folder,
        Dir.glob(OnBoard::ROOTDIR + '/public')            +
        Dir.glob(OnBoard::ROOTDIR + '/modules/*/public')

    set :views, OnBoard::ROOTDIR + '/views'

    not_found do
      @override_not_found ||= false
      status 404
      if @override_not_found
        pass
      else
        format(:path=>'404', :format=>'html')
      end
    end

    # modular controller
    OnBoard.find_n_load OnBoard::ROOTDIR + '/controller/'

  end

end
