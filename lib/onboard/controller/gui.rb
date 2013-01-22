class OnBoard
  class Controller < ::Sinatra::Base

    # TODO: do not hardcode, make it themable :-)
    IconDir = '/icons/gnome/gnome-icon-theme-2.18.0'
    IconSize = '16x16'

    public_access! %r{^/backgrounds/} 

    public_access! %r{^/icons/} 

  end
end
