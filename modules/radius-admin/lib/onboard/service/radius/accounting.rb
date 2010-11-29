require 'sequel'
require 'sequel/extensions/pagination'

class OnBoard
  module Service
    module RADIUS
      module Accounting

        class << self
        
          def get(params)
            page      = params[:page].to_i
            per_page  = params[:per_page].to_i
            {
              'rows'        => 
                  RADIUS.db[:radacct].paginate(page, per_page).to_a,
              'total_items' => 
                  RADIUS.db[:radacct].count,
              'page'        => page,
              'per_page'    => per_page
            }
          end

        end

      end
    end
  end
end 
