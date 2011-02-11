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

        end
      end
    end
  end
end
