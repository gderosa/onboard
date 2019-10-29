# encoding: UTF-8

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

      def main_menu
        OnBoard::MENU_ROOT.to_html_ul do |node, output|
          if node.content

            # if a "children rule" is not specified, create it (if possible)
            if node.content[:href] and not node.content[:children]
              node.content[:children] = /^#{node.content[:href].to_dir}/
            end

            if request.path_info ==  node.content[:href]
              output[:href] = nil
              output[:extra_class] = "hmenu-selected"
            # That's why I love Ruby: node.content[:children] may
            # be a String, a Regexp or even a block of code! (lambda)
            elsif node.content[:children] === request.path_info
              output[:extra_class] = "hmenu-selected" unless
                  # do not highlight if any descendant matches already
                  node.any? do |n|
                    n.content                                   and (
                      n.content[:href]      ==  request.path_info or
                      n.content[:children]  === request.path_info and
                      n                     !=  node # exclude itself
                    )
                  end
            end
          end
        end
      end

    end
  end
end
