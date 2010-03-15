
class OnBoard
  module Service
    module RADIUS
      module Accounting

        class << self
        
          def get(params)
            RADIUS.db[:radacct]
          end

        end

      end
    end
  end
end 
