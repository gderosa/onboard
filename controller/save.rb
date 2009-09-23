require 'sinatra/base'

class OnBoard::Controller

  get "/save.html" do
    format(
      :path     => '/save',
      :format   => 'html'
    )
  end

  post "/save.html" do
    OnBoard.save! if params['save'] =~ /yes/i
    format(
      :path     => '/save',
      :format   => 'html'
    )
  end

end
