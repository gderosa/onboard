require 'tree'

require 'onboard/extensions/tree'

class OnBoard
  module Menu
    class MenuNode < Tree::TreeNode
      DEBUG = false

      # "smart getter" for MenuNode#content[:n]
      def n
        begin
          content[:n] ? content[:n] : 0
        rescue
          0
        end
      end

      # MenuNode#content[:n] is used to force menu items sorting;
      # otherwise sorting is made by "displayed name"
      def <=>(other)
        compare = (n <=> other.n) 
        if compare == 1 or compare == -1
          return compare
        elsif content and other.content and 
            content[:name] and other.content[:name]
          compare = (content[:name] <=> other.content[:name])
          return compare if compare
        elsif name and other.name
          return name.capitalize <=> other.name.capitalize # as printed
        else
          return 0
        end
      end

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
                  '<span title="' << (content[:desc] or '') << '"' << 
                  (hasChildren? ? '' : ' class="lowlight"' ) << 
                  '>' << 
                    content[:name] << 
                  '</span>'
            end
          else
            s << name.capitalize
          end
          s << " (#{self.n})" if DEBUG
        end
        if hasChildren?
          s += "<ul>"
          children.sort.each_with_index do |child, debug_idx|
            s += "<li>" << child.to_html_ul << "</li>"
          end
          s += "</ul>"
        end
        return s
      end
    end
  end
end
