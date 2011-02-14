require 'dansguardian/list'
require 'onboard/content-filter/dg/managed-list/filepath-mixin'

class OnBoard
  module ContentFilter
    class DG
      module ManagedList
        class List

          include ManagedList::FilePathMixin

          def initialize(h)
            @relative_path  = h[:relative_path]
            @data           = ::DansGuardian::List.new(absolute_path)
          end

          def items; @data.items; end

          def includes
            @data.includes.map{|path| ManagedList.relative_path path}  
          end

          def <=>(other)
            if other.is_a? ManagedList::Dir
              +1 # list directories before files
            else
              @relative_path <=> other.relative_path
            end
          end

        end
      end
    end
  end
end
