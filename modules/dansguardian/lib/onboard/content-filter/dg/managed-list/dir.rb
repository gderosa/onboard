# A directory of DansGuardian lists

require 'onboard/content-filter/dg/managed-list/filepath-mixin'

class OnBoard
  module ContentFilter
    class DG
      module ManagedList
        class Dir

          include ::Enumerable
          include ManagedList::FilePathMixin

          def initialize(h)
            @relative_path = h[:relative_path]
          end

          def each
            ::Dir.foreach absolute_path do |item|
              next if item =~ /^\./ # skip hidden, '.' and '..'
              yield ManagedList.get( File.join( @relative_path, item ) )
            end
          end

        end
      end
    end
  end
end
