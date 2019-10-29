class OnBoard
  class Controller < ::Sinatra::Base

    # TODO: do not hardcode, make it themable :-)
    IconDir = '/icons/gnome/gnome-icon-theme-2.18.0'
    IconSize = '16x16'

    # TODO? Move all colors etc. here from default.css.erb
    DEFAULT_THEME = {
      :highlight      =>  "#44b",
      :lowlight       =>  "#666",
    }

    public_access! %r{^/backgrounds/}

    public_access! %r{^/icons/}

  end
end
