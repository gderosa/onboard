class OnBoard
  module ContentFilter
    class DG
      class FilterGroup

        class << self
          def get(id)
            new(
              :id => id
            )
          end
        end
          
        def initialize(h)
          @id   = h[:id]
          @file = DG.fg_file(@id)
        end

        def update!(params)
          pp params
        end

      end
    end
  end
end
