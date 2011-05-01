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

          def <=>(other)
            if other.is_a? ManagedList::List
              -1 # list directories before files
            else
              @relative_path <=> other.relative_path
            end
          end

          def export
            a = []
            self.each do |item|
              a << {
                'type' => (
                            case item
                            when ManagedList::List
                              'list'
                            when ManagedList::Dir
                              'dir'
                            else
                              'unknown'
                            end
                          ),
                'name' => File.basename(item.relative_path)
              }
            end
            {
              'relative_path' => @relative_path,
              'items'         => a
            }
          end

          def to_json(*args); export.to_json(*args); end
          def to_yaml(*args); export.to_yaml(*args); end

        end
      end
    end
  end
end
