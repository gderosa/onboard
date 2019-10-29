require 'sinatra/base'

class OnBoard::Controller

  # no homepage for Web Services ;-P

  get "/home.?:format/?" do
    redirect "/"
  end

  get "/" do
    begin
      format(
        :path     => 'home-custom',
        :format   => 'html',
        :objects  =>  []
      )
    rescue Errno::ENOENT
      format(
        :path     => 'home',
        :format   => 'html',
        :objects  =>  []
      )
    end
  end

end
