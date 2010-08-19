require 'sinatra/base'

class OnBoard::Controller

  get "/configuration/save.html" do
    format(
      :path     => '/configuration/save',
      :format   => 'html',
      :title    => 'Save configuration'
    )
  end

  post "/configuration/save.html" do
    OnBoard.save! if params['save'] =~ /yes/i
    format(
      :path     => '/configuration/save',
      :format   => 'html',
      :title    => 'Save configuration'
    )
  end

  get "/configuration/export.html" do
    format(
      :path     => '/configuration/export',
      :format   => 'html',
      :title    => 'Export Configuration'
    )
  end


end
