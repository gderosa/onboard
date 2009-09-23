require 'sinatra/base'

class OnBoard::Controller

  get "/network.html" do
    format(
      :path     => 'simple_menu',
      :format   => 'html',
      :objects  => {
        :menu     => OnBoard::MENU_ROOT['network'],
        :title    => 'Network',
        :desc     => nil
      }
    )
  end

end
