class OnBoard
  class Controller < Sinatra::Base

    # just to have "CSS variables"
    get '/css/:stylesheet' do
      content_type 'text/css'
      erubis ('css/' + params[:stylesheet]).to_sym
    end

  end
end
