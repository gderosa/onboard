require 'hmenu'

class OnBoard
  module Menu
    # very simple "delegation" to +HMenu::Node+ class. See documentation
    # for 'hierarchical_menu' on rubygems.org .
    class MenuNode < ::HMenu::Node; end
  end
end

