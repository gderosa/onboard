require 'hmenu'

class OnBoard
  module Menu
    class MenuNode < ::HMenu::Node

      # wrapper method
      def add_path(path, hash)
        new_hash = hash.dup
        new_hash[:href] = hash[:href] + '.html' if  hash[:href]
        super(path, new_hash)
      end

    end
  end
end

