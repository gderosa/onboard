require 'tree'

require 'onboard/extensions/tree'

class OnBoard
  module Menu
    class MenuNode < Tree::TreeNode
      def to_html_ul
        # TODO: use CSS+Javascript to show/hide subitems on click
        s = ""
        if isRoot?
          s << "<a href=\"/\">Home</a>"
        else
          if content 
            if content[:href]
              s << 
                "<a " << 
                  "title=\"#{content[:desc]}\" " << 
                  "href=\"#{content[:href]}.html\">#{content[:name]}" <<
                "</a>"
            elsif content[:name]
              s << 
                  '<span title="' << content[:desc] << '">' << 
                    content[:name] << 
                  '</span>'
            end
          else
            s << name.capitalize
          end
        end
        if hasChildren?
          s += "<ul>"
          children.sort.each do |child|
            s += "<li>" << child.to_html_ul << "</li>"
          end
          s += "</ul>"
        end
        return s
      end
      def <=>(other) # for sorting
        n <=> other.n 
      end
      def n
        begin
          content[:n] ? content[:n] : 0
        rescue
          0
        end
      end
    end
  end
end
