require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/hash'
require 'onboard/service/radius/db'

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
              columns.symbolize_all.invert
            )
            rows      = []
            RADIUS::Db.handle_errors do
              rows      = select.paginate(page, per_page).to_a
            end
            {
              'rows'        => rows,
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
