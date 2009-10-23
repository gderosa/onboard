require 'sinatra/base'

class OnBoard::Controller

  get "/network/nat.html" do
    format(
      :path     => 'simple_menu',
      :format   => 'html',
      :objects  => {
        :menu     => OnBoard::MENU_ROOT['network']['nat'],
        :title    => 'Network Address Translation',
        :desc     => 'Share connection to and from the public Internet'
      }
    )
  end

end
