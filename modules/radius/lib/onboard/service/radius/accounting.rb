
class OnBoard
  module Service
    module RADIUS
      module Accounting

        class << self
        
          def get(params)
            RADIUS.db[:radacct].to_a
          end

        end

      end
    end
  end
end 
