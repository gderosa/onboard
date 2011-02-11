# A directory of DansGuardian lists

class OnBoard
  module ContentFilter
    class DG
      module ManagedList
        module FilePathMixin

          attr_reader :relative_path
          
          def absolute_path
            File.join ManagedList.root_dir, @relative_path
          end

          def http_path
            "/content-filter/dansguardian/lists/#{@relative_path}"
          end

        end
      end
    end
  end
end
