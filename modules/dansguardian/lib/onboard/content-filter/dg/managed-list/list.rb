require 'onboard/content-filter/dg/managed-list/filepath-mixin'

class OnBoard
  module ContentFilter
    class DG
      module ManagedList
        class List

          include ManagedList::FilePathMixin

          def initialize(h)
            @relative_path = h[:relative_path]
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
