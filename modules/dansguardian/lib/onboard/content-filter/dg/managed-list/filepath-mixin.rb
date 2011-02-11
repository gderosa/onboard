# A directory of DansGuardian lists

class OnBoard
  module ContentFilter
    class DG
      module ManagedList
        module FilePathMixin

          def absolute_path
            File.join ManagedList.root_dir, @relative_path
          end

        end
      end
    end
  end
end
