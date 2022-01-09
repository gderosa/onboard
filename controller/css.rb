class OnBoard
  class Controller < Sinatra::Base

    public_access! %r{^/css/}

    # just to have "CSS variables"
    get '/css/default.css' do
      content_type 'text/css'
      erb (:"css/default.css")
    end

    get '/css/jqueryui-fixes.css' do
      content_type 'text/css'
      erb (:"css/jqueryui-fixes.css")
    end

    get '/css/default.mobi.css' do
      content_type 'text/css'
      erb (:"css/default.mobi.css")
    end

    get '/css/custom.css' do
      send_file CONFDIR + '/self/custom.css'
    end

  end
end
