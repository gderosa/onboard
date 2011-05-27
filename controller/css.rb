class OnBoard
  class Controller < Sinatra::Base

    # just to have "CSS variables"
    get '/css/default.css' do
      content_type 'text/css'
      erubis (:"css/default.css")
    end

    get '/css/custom.css' do
      send_file CONFDIR + '/self/custom.css'
    end

  end
end
