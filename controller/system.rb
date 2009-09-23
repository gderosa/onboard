require 'sinatra/base'

class OnBoard::Controller

  get "/system.html" do
    format(
      :path     => 'simple_menu',
      :format   => 'html',
      :objects  => {
        :menu     => OnBoard::MENU_ROOT['system'],
        :title    => 'System management',
        :desc     => nil
      }
    )
  end

end
