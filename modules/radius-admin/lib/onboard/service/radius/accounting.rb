require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/hash'
require 'onboard/extensions/sequel'

class OnBoard
  module Service
    module RADIUS
      module Accounting

        class << self
        
          def get(params)
            conf      = RADIUS.read_conf
            table     = conf['accounting']['table'].to_sym
            columns   = conf['accounting']['columns']
            page      = params[:page].to_i
            per_page  = params[:per_page].to_i
            select    = RADIUS.db[table].select(
              *Sequel.aliases(columns.invert)
            )
            {
              'rows'        => select.paginate(page, per_page).to_a,
              'total_items' => select.count,
              'page'        => page,
              'per_page'    => per_page
            }
          end

        end

      end
    end
  end
end 
