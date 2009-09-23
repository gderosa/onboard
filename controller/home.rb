require 'sinatra/base'

class OnBoard::Controller

  # no homepage for Web Services ;-P

  get "/home.?:format/?" do
    redirect "/"
  end

  get "/" do
    format(
      :path     => 'home',
      :format   => 'html',
      :objects  =>  []
    ) 
  end

end
