require 'sinatra/base'

class OnBoard::Controller

  title = 'Save configuration'

  get "/save.html" do
    format(
      :path     => '/save',
      :format   => 'html',
      :title    => title
    )
  end

  post "/save.html" do
    OnBoard.save! if params['save'] =~ /yes/i
    format(
      :path     => '/save',
      :format   => 'html',
      :title    => title
    )
  end

end
